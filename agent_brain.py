import os
import asyncio

async def async_exec_cmd(cmd):
    proc = await asyncio.create_subprocess_shell(
        cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT
    )
    stdout, _ = await proc.communicate()
    return stdout.decode('utf-8'), proc.returncode

async def analyze_runtime_integrity():
    issues = []
    tasks = []
    task_info = []

    # 1. Dependency Analysis (NPM/PIP check)
    if os.path.exists('package.json'):
        print("Analyzing Node Dependencies...")
        tasks.append(async_exec_cmd("npm audit --json"))
        task_info.append(("npm", "security"))
    
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
        tasks.append(async_exec_cmd("./gradlew properties"))
        task_info.append(("android", "build"))

    if tasks:
        results = await asyncio.gather(*tasks)
        for (out, code), (ecosystem, issue_type) in zip(results, task_info):
            if code != 0:
                if ecosystem == "npm" and issue_type == "security":
                     issues.append({"type": "security", "ecosystem": "npm", "details": "Vulnerabilities detected"})
                elif ecosystem == "android" and issue_type == "build":
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

async def main():
    print("Agentic Brain: Scanning for Inoperable Errors...")
    detected_issues = await analyze_runtime_integrity()
    
    if not detected_issues:
        print("Agentic Brain: Repository Logic is Nominal.")
        return
        
    print(f"Agentic Brain: Detected {len(detected_issues)} non-functional errors.")
    solutions = formulate_solution(detected_issues)
    
    if solutions:
        print(f"Executing {len(solutions)} Corporate Fixes concurrently...")
        tasks = []
        for sol in solutions:
            print(f"Executing Corporate Fix: {sol}")
            tasks.append(async_exec_cmd(sol))

        results = await asyncio.gather(*tasks)
        for out, code in results:
            print(out)

if __name__ == "__main__":
    asyncio.run(main())
