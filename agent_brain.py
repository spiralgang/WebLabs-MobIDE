import subprocess
import sys
import os

def exec_cmd(cmd):
    try:
        result = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)
        return result.decode('utf-8'), 0
    except subprocess.CalledProcessError as e:
        return e.output.decode('utf-8'), e.returncode

def analyze_runtime_integrity():
    issues = []
    
    # 1. Dependency Analysis (NPM/PIP check)
    if os.path.exists('package.json'):
        print("Analyzing Node Dependencies...")
        out, code = exec_cmd("npm audit --json")
        if code != 0:
            issues.append({"type": "security", "ecosystem": "npm", "details": "Vulnerabilities detected"})
    
    if os.path.exists('requirements.txt'):
        print("Analyzing Python Dependencies...")
        # Heuristic: Check for pinned versions
        with open('requirements.txt', 'r') as f:
            content = f.read()
            if '==' not in content:
                issues.append({"type": "stability", "ecosystem": "python", "details": "Unpinned dependencies"})

    # 2. Build Integrity Analysis
    if os.path.exists('gradlew'):
        print("Analyzing Gradle Build Integrity...")
        out, code = exec_cmd("./gradlew properties")
        if code != 0:
             issues.append({"type": "build", "ecosystem": "android", "details": "Gradle configuration failure"})

    return issues

def formulate_solution(issues):
    fixes = []
    for issue in issues:
        print(f"Resolving Issue: {issue}")
        
        if issue['ecosystem'] == 'npm' and issue['type'] == 'security':
            # Agentic Decision: Force Fix
            cmd = "npm audit fix --force"
            fixes.append(cmd)
        
        if issue['ecosystem'] == 'android' and issue['type'] == 'build':
            # Agentic Decision: Clean and Rebuild Cache
            cmd = "chmod +x gradlew && ./gradlew clean"
            fixes.append(cmd)
        
        if issue['ecosystem'] == 'python' and issue['type'] == 'stability':
            # Agentic Decision: Generate freeze (Approximation)
            cmd = "pip install -r requirements.txt && pip freeze > requirements.lock"
            fixes.append(cmd)
            
    return fixes

def main():
    print("Agentic Brain: Scanning for Inoperable Errors...")
    detected_issues = analyze_runtime_integrity()
    
    if not detected_issues:
        print("Agentic Brain: Repository Logic is Nominal.")
        sys.exit(0)
        
    print(f"Agentic Brain: Detected {len(detected_issues)} non-functional errors.")
    solutions = formulate_solution(detected_issues)
    
    for solution in solutions:
        print(f"Executing Corporate Fix: {solution}")
        out, code = exec_cmd(solution)
        print(out)

if __name__ == "__main__":
    main()
