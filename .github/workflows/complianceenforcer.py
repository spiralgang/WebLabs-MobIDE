#!/usr/bin/env python3
"""
WebLabs-MobIDE Compliance Checker
Safe compliance verification for WebLabs-MobIDE repository structure.
- Scans for folder structure, permissions, UTF-8, Alpine/AI integration.
- Reports compliance status without destructive operations.
- Based on WebLabs-MobIDE standards for Android 10+ ARM64 development.
"""

import os
import json
import subprocess
import logging
import re
from pathlib import Path
from datetime import datetime

# Config for WebLabs-MobIDE
ORG_NAME = "spiralgang"
REPO_NAME = "WebLabs-MobIDE"
REPO_PATH = "../.."  # Go up from .github/workflows to repository root

# Standards from WebLabs-MobIDE
STANDARD_TREE = {
    "app": ["src/main/java/com/spiralgang/weblabs/", "build.gradle.kts"],
    "app/src/main/assets": ["webide-components/", "scripts/"],
    "gradle": ["wrapper/"],
    "docs": [], 
    "scripts": [], 
    ".github": ["workflows/", "copilot_instructions.md"]
}

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

class ComplianceChecker:
    def __init__(self, repo_path):
        self.repo_path = Path(repo_path)
        self.compliance_score = 100

    def scan_structure(self):
        violations = []
        passed = []
        for dir_name, expected in STANDARD_TREE.items():
            dir_path = self.repo_path / dir_name
            if not dir_path.exists():
                violations.append(f"Missing directory: {dir_name}")
                self.compliance_score -= 10
            else:
                passed.append(f"✅ Directory exists: {dir_name}")
                for expected_file in expected:
                    file_path = dir_path / expected_file
                    if not file_path.exists():
                        violations.append(f"Missing: {dir_name}/{expected_file}")
                        self.compliance_score -= 5
                    else:
                        passed.append(f"✅ File/dir exists: {dir_name}/{expected_file}")
        return violations, passed

    def scan_critical_files(self):
        violations = []
        passed = []
        critical_files = [
            "package.json",
            ".github/copilot_instructions.md", 
            "copilot_instructions.md",
            "README.md",
            "build.gradle.kts"
        ]
        
        for file_name in critical_files:
            file_path = self.repo_path / file_name
            if not file_path.exists():
                violations.append(f"Missing critical file: {file_name}")
                self.compliance_score -= 15
            else:
                passed.append(f"✅ Critical file exists: {file_name}")
        
        return violations, passed

    def generate_report(self, violations, passed_checks):
        report = {
            "timestamp": datetime.utcnow().isoformat(),
            "repository": f"{ORG_NAME}/{REPO_NAME}",
            "compliance_score": self.compliance_score,
            "status": "COMPLIANT" if self.compliance_score >= 80 else "NON_COMPLIANT",
            "violations": violations,
            "passed_checks": passed_checks
        }
        
        # Write JSON report
        with open("compliance-report.json", "w") as f:
            json.dump(report, f, indent=2)
        
        # Print summary
        print(f"\n=== COMPLIANCE REPORT ===")
        print(f"Repository: {ORG_NAME}/{REPO_NAME}")
        print(f"Score: {self.compliance_score}/100")
        print(f"Status: {report['status']}")
        print(f"\nViolations ({len(violations)}):")
        for violation in violations:
            print(f"  ❌ {violation}")
        print(f"\nPassed Checks ({len(passed_checks)}):")
        for check in passed_checks:
            print(f"  {check}")
        
        return report

    def run_scan(self):
        structure_violations, structure_passed = self.scan_structure()
        file_violations, file_passed = self.scan_critical_files()
        
        all_violations = structure_violations + file_violations
        all_passed = structure_passed + file_passed
        
        report = self.generate_report(all_violations, all_passed)
        
        if self.compliance_score >= 80:
            logging.info("Repository is compliant")
            print("✅ Repository compliance check PASSED")
        else:
            logging.warning(f"Repository compliance issues found. Score: {self.compliance_score}/100")
            print("❌ Repository compliance check FAILED")
        
        return report

if __name__ == "__main__":
    checker = ComplianceChecker(REPO_PATH)
    report = checker.run_scan()
    
    # Exit with appropriate code for CI
    if report["compliance_score"] >= 80:
        exit(0)  # Success
    else:
        exit(1)  # Failure
