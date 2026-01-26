import os
import re
import shutil
import sys
import json
from datetime import datetime

# NEON COLORS FOR PYTHON
CYAN = '\033[1;36m'
GREEN = '\033[1;32m'
RESET = '\033[0m'

class RepositoryState:
    def __init__(self):
        self.files = []
        self.dirs = []
        self.health_score = 100
        self.anomalies = []

    def scan(self):
        for root, d, f in os.walk('.'):
            if '.git' in root or '.quantum_logs' in root: continue
            for file in f:
                self.files.append(os.path.join(root, file))
            for directory in d:
                self.dirs.append(os.path.join(root, directory))

class FiniteStateMachine:
    def __init__(self, repo_state):
        self.state = 'IDLE'
        self.repo = repo_state
        self.changes_made = []

    def transition(self, new_state):
        print(f"{CYAN}[CORTEX FSM] Transitioning: {self.state} -> {new_state}{RESET}")
        self.state = new_state

    def execute_cycle(self):
        self.transition('ANALYZING_STRUCTURE')
        self._enforce_directory_standards()
        
        self.transition('ANALYZING_NAMING')
        self._enforce_naming_conventions()
        
        self.transition('OPTIMIZING_FILESYSTEM')
        self._clean_legacy_artifacts()
        
        self.transition('COMMITTING')
        return self.changes_made

    def _enforce_directory_standards(self):
        # Heuristic: Every repo needs specific folders
        required_dirs = ['docs', 'scripts', 'tests']
        for d in required_dirs:
            if not os.path.exists(d):
                os.makedirs(d)
                self.changes_made.append(f"Created standard directory: {d}")
                print(f"{GREEN}Structure Enforced: +{d}/{RESET}")

    def _enforce_naming_conventions(self):
        # Heuristic: Whitespace in filenames is inefficient for CLI operations
        for filepath in self.repo.files:
            filename = os.path.basename(filepath)
            dirname = os.path.dirname(filepath)
            
            if ' ' in filename:
                new_name = filename.replace(' ', '_').lower()
                new_path = os.path.join(dirname, new_name)
                shutil.move(filepath, new_path)
                self.changes_made.append(f"Renamed: {filename} -> {new_name}")
                print(f"{GREEN}Naming Enforced: {filename} -> {new_name}{RESET}")

    def _clean_legacy_artifacts(self):
        # Heuristic: Delete temp files that clutter the repo
        junk_extensions = ['.tmp', '.log', '.bak', '.swp']
        # Exclude our quantum logs
        for filepath in self.repo.files:
            if any(filepath.endswith(ext) for ext in junk_extensions):
                if '.quantum_logs' not in filepath:
                    os.remove(filepath)
                    self.changes_made.append(f"Purged artifact: {filepath}")
                    print(f"{GREEN}Filesystem Optimized: -{filepath}{RESET}")

def main():
    print(f"{CYAN}Initializing Synthetic Cortex Engine...{RESET}")
    repo = RepositoryState()
    repo.scan()
    
    fsm = FiniteStateMachine(repo)
    changes = fsm.execute_cycle()
    
    # Output Report for Phase 3 to read (but Phase 2 acts independently)
    with open('cortex_report.json', 'w') as f:
        json.dump(changes, f)
        
    if changes:
        print(f"{GREEN}Cortex Cycle Complete. {len(changes)} structural modifications applied.{RESET}")
    else:
        print(f"{GREEN}Cortex Cycle Complete. Repository structure is nominal.{RESET}")

if __name__ == "__main__":
    main()
