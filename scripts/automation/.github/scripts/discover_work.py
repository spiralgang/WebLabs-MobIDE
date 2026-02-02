# discover_work.py
# This script scans the repository to identify modules and AI-driven tasks.
# It outputs a JSON matrix for use in subsequent GitHub Actions jobs.
#
import os
import glob
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
    
    for root, _, files in os.walk('.'):
        # Ignore dot-folders like .github, .git
        if any(part.startswith('.') for part in root.split(os.path.sep)):
            continue

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
    
    source_files = glob.glob('**/*', recursive=True)
    
    for file_path in source_files:
        if os.path.isfile(file_path) and not any(d in file_path for d in ['.git/', '.github/']):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    for i, line in enumerate(f):
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
