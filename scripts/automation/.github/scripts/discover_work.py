# discover_work.py
# This script scans the repository to identify modules and AI-driven tasks.
# It outputs a JSON matrix for use in subsequent GitHub Actions jobs.
#
import os
import json
import re

def set_github_output(name, value):
    """Sets an output variable for GitHub Actions."""
    github_output_path = os.environ.get('GITHUB_OUTPUT')
    if github_output_path:
        with open(github_output_path, 'a') as f:
            f.write(f"{name}={value}\n")

def discover_work():
    """
    Performance Optimization:
    Combines module discovery and AI task discovery into a single-pass `os.walk` traversal.

    Optimizations applied:
    1. In-place directory pruning (`dirs[:] = ...`): Completely avoids descending into ignored
       hidden directories (.git, .github) and build/dependency directories (node_modules, build, etc.),
       reducing file system traversal operations significantly.
    2. Fast-path binary check: Scans the first 1024 bytes for null bytes (b'\0') to instantly skip
       large binary files without full text decoding.
    3. Fast-path substring check: Performs 'TODO-AI' and 'FIXME-AI' string containment check on full
       file content before attempting line-by-line regex matching.
    4. Fixed module discovery: Correctly resolves root and sub-directory paths and maps manifest
       files ('requirements.txt', 'package.json', 'go.mod', 'pom.xml', 'build.gradle', 'pyproject.toml')
       to their module types.
    """
    print("Discovering modules and evolution tasks...")
    modules = []
    tasks = []

    dependency_files = {
        'requirements.txt': 'python',
        'pyproject.toml': 'python',
        'package.json': 'nodejs',
        'go.mod': 'go',
        'pom.xml': 'java',
        'build.gradle': 'java'
    }
    task_pattern = re.compile(r'.*(TODO-AI|FIXME-AI):\s*(.*)')

    for root, dirs, files in os.walk('.'):
        # In-place directory pruning to avoid traversing ignored hidden folders and heavy dependencies
        dirs[:] = [d for d in dirs if not (
            d.startswith('.') or
            d in ('node_modules', 'build', 'dist', 'bin', 'obj', 'out')
        )]

        # 1. Discover modules
        for dep_file, mod_type in dependency_files.items():
            if dep_file in files:
                module_path = root if root != '.' else './'
                print(f"  Found '{mod_type}' module at '{module_path}'")
                modules.append({'module': module_path, 'module_type': mod_type})
                break  # Max one module entry per directory

        # 2. Discover evolution tasks in files
        for file_name in files:
            file_path = os.path.join(root, file_name)
            try:
                # Fast binary file check: inspect first 1KB for null bytes
                with open(file_path, 'rb') as f:
                    chunk = f.read(1024)
                    if b'\0' in chunk:
                        continue

                # Read text and check fast substring containment before regex
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    if 'TODO-AI' not in content and 'FIXME-AI' not in content:
                        continue

                    for i, line in enumerate(content.splitlines()):
                        match = task_pattern.match(line)
                        if match:
                            task_desc = match.group(2).strip()
                            task_id = f"{os.path.basename(file_path)}-L{i+1}"
                            print(f"  Found task '{task_desc}' in {file_path}")
                            tasks.append({
                                'task_id': task_id,
                                'file_path': file_path,
                                'line_number': i + 1,
                                'task_description': task_desc
                            })
            except Exception:
                continue

    return modules, tasks

def main():
    """Main discovery and matrix generation logic."""
    improvement_modules, evolution_tasks = discover_work()
    
    has_work = bool(improvement_modules or evolution_tasks)
    
    # Format for GitHub Actions matrix
    improvement_matrix = {'include': improvement_modules}
    evolution_matrix = {'include': evolution_tasks}
    
    print("\n--- MATRIX GENERATION ---")
    print(f"Improvement Matrix: {json.dumps(improvement_matrix)}")
    print(f"Evolution Matrix: {json.dumps(evolution_matrix)}")
    
    set_github_output('improvement_matrix', json.dumps(improvement_matrix))
    set_github_output('evolution_matrix', json.dumps(evolution_matrix))
    set_github_output('has_work', str(has_work).lower())
    print("\nDiscovery complete. Outputs set.")

if __name__ == "__main__":
    main()
