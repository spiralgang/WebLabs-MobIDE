import os
import re
import shutil
import sys

WORKFLOW_DIR = '.github/workflows'
ARCHIVE_DIR = 'archive/workflows/lineage'

def evolve():
    # 1. Identify Current Generation
    # We look for files matching *codepilot.yml
    candidates = []
    for f in os.listdir(WORKFLOW_DIR):
        if f.endswith('codepilot.yml'):
            # Extract number
            match = re.match(r'(\d*)codepilot\.yml', f)
            if match:
                num = int(match.group(1)) if match.group(1) else 1
                candidates.append((num, f))
    
    if not candidates:
        print("Critical: No Genesis file found.")
        sys.exit(1)
    
    # Sort to find the highest number (current active agent)
    candidates.sort(key=lambda x: x[0])
    current_gen_num, current_filename = candidates[-1]
    
    print(f"Identified Active Agent: Generation {current_gen_num} ({current_filename})")
    
    # 2. Archive Ancestors (and Self)
    if not os.path.exists(ARCHIVE_DIR):
        os.makedirs(ARCHIVE_DIR)
        
    src_path = os.path.join(WORKFLOW_DIR, current_filename)
    
    # Rename current to backup with signature
    backup_name = f"gen_{current_gen_num}_ancestor.yaml.bak"
    dest_path = os.path.join(ARCHIVE_DIR, backup_name)
    
    print(f"Archiving Ancestor: {src_path} -> {dest_path}")
    shutil.move(src_path, dest_path)
    
    # Git Remove the old file (staged)
    os.system(f"git rm {src_path}")
    # Git Add the archive (staged)
    os.system(f"git add {ARCHIVE_DIR}")

    # 3. Spawn Successor
    # The successor inherits the EXACT content of the current script (which we are running inside)
    # But since we moved the file, we need to copy from the archive back to workflows with new name
    
    next_gen_num = current_gen_num + 1
    next_filename = f"{next_gen_num}codepilot.yml"
    next_path = os.path.join(WORKFLOW_DIR, next_filename)
    
    print(f"Spawning Successor: Generation {next_gen_num} ({next_filename})")
    shutil.copy(dest_path, next_path)
    
    # Git Add the new file
    os.system(f"git add {next_path}")
    
    return next_gen_num

if __name__ == "__main__":
    try:
        new_gen = evolve()
        print(f"Evolution Successful. Welcome Gen {new_gen}.")
    except Exception as e:
        print(f"Evolution Failure: {e}")
        sys.exit(1)
