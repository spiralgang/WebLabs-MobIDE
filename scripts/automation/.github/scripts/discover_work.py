# discover_work.py
# This script scans the repository to identify modules and AI-driven tasks.
# It outputs a JSON matrix for use in subsequent GitHub Actions jobs.
#
import os
import json
import re

def set_github_output(name, value):
    """Sets an output variable for GitHub Actions."""
    with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
        f.write(f"{name}={value}\n")

def find_modules():
    """
    Discovers modules in the repository.
    A module is defined by the presence of a known dependency file.
    """
    print("Discovering modules...")
    modules = []
    dependency_files = [
        'requirements.txt', 'pyproject.toml',  # Python
        'package.json',                        # Node.js
        'go.mod',                              # Go
        'pom.xml', 'build.gradle'              # Java/Kotlin
    ]
    
    # Performance: Prune dot-folders in-place so os.walk avoids visiting hidden directories
    # like .git, .github, .jules, etc., saving massive disk I/O operations and traversal overhead.
    # This also fixes a pre-existing bug where root directory '.' was skipped because of parts check.
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not d.startswith('.')]

        for dep_file in dependency_files:
            if dep_file in files:
                module_path = root if root != '.' else './'
                module_type = 'unknown'
                if dep_file in ['requirements.txt', 'pyproject.toml']:
                    module_type = 'python'
                elif dep_file == 'package.json':
                    module_type = 'nodejs'
                
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
    
    source_files = []
    # Performance: Avoid glob.glob('**/*', recursive=True) as it lists all nested git/github objects.
    # Instead, we traverse with os.walk and prune hidden and standard ignored folders in-place.
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('node_modules', 'dist', 'build')]
        for f in files:
            source_files.append(os.path.join(root, f))
    
    for file_path in source_files:
        if os.path.isfile(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    # Performance: Use a fast substring check before performing line-by-line regex.
                    # This avoids O(n) line-by-line regex iteration on files lacking these annotations.
                    content = f.read()
                    if 'TODO-AI' not in content and 'FIXME-AI' not in content:
                        continue

                    # Performance: Iterate over in-memory lines to keep operations purely in-memory
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
                continue # Ignore binary files or read errors
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
