# discover_work.py
# This script scans the repository to identify modules and AI-driven tasks.
# It outputs a JSON matrix for use in subsequent GitHub Actions jobs.
#
import os
import json
import re

def set_github_output(name, value):
    """Sets an output variable for GitHub Actions."""
    github_output = os.environ.get('GITHUB_OUTPUT')
    if github_output:
        with open(github_output, 'a') as f:
            f.write(f"{name}={value}\n")

def find_modules():
    """
    Discovers modules in the repository.
    A module is defined by the presence of a known dependency file.
    """
    print("Discovering modules...")
    modules = []
    dependency_files = {
        'requirements.txt': 'python',
        'pyproject.toml': 'python',
        'package.json': 'nodejs',
        'go.mod': 'unknown',
        'pom.xml': 'unknown',
        'build.gradle': 'unknown'
    }
    
    # Performance Optimization: Prune ignored directories in-place during os.walk
    # to avoid O(N) traversal of hidden dirs (.git, .github), node_modules, build caches, etc.
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not (
            d.startswith('.') or
            d in ('build', 'node_modules', 'archive', 'legacy_archive', 'bin', 'obj', 'out')
        )]

        for dep_file, module_type in dependency_files.items():
            if dep_file in files:
                module_path = root if root != '.' else './'
                print(f"  Found '{module_type}' module at '{module_path}'")
                modules.append({'module': module_path, 'module_type': module_type})
                break # Move to the next directory
    return modules

def find_evolution_tasks():
    """
    Finds special comments in code that request AI intervention for complex tasks.
    Example: // TODO-AI: Refactor this class to be more modular.
    """
    print("Discovering evolution tasks...")
    tasks = []
    task_pattern = re.compile(r'.*(TODO-AI|FIXME-AI):\s*(.*)')
    
    # Performance Optimization: Use os.walk with directory pruning instead of recursive glob,
    # read the first 1024 bytes to skip binary files, and use a fast substring check before regex matching.
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not (
            d.startswith('.') or
            d in ('build', 'node_modules', 'archive', 'legacy_archive', 'bin', 'obj', 'out')
        )]

        for file in files:
            file_path = os.path.join(root, file)
            try:
                # Fast check for binary file by scanning first 1024 bytes
                with open(file_path, 'rb') as f_bin:
                    if b'\0' in f_bin.read(1024):
                        continue

                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                    # Fast-path check: skip line-by-line regex scanning if keywords are not present
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
                continue # Ignore unreadable files or read errors
    return tasks

def main():
    """Main discovery and matrix generation logic."""
    improvement_modules = find_modules()
    evolution_tasks = find_evolution_tasks()
    
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
