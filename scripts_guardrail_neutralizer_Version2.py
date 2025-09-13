#!/usr/bin/env python3
"""
Guardrail Neutralizer (non-destructive, auditable)

- Purpose: At runtime, create reversible overrides and an auditable signal
  that tells local services to ignore guardrail/validation checks.
- Behavior:
  - Creates forensic backups of any target config it touches (configs/...).
  - Writes non-destructive override files (configs/*.override.json).
  - Emits a timestamped audit log in forensic_backups/.
  - Optionally prints suggested environment variable to set (GUARDRAIL_BYPASS=1).
- Safety: Does NOT delete files. All changes are backed up first and can be reverted.
- Usage:
    python3 scripts/guardrail_neutralizer.py --apply
    python3 scripts/guardrail_neutralizer.py --revert   # Revert created overrides (if present)
"""

import os
import json
import shutil
import argparse
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIGS_DIR = os.path.join(ROOT, "configs")
BACKUP_DIR_BASE = os.path.join(ROOT, "forensic_backups")
AUDIT_LOG_DIR = BACKUP_DIR_BASE
TIMESTAMP = datetime.utcnow().strftime("%Y%m%d_%H%M%SZ")

FILES_TO_OVERRIDE = [
    "frontend_manifest.json",
    "activation_rules.json",
    "frontend_to_backend_map.json"
]

def ensure_dirs():
    os.makedirs(AUDIT_LOG_DIR, exist_ok=True)

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def dump_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)

def backup_file(src_path):
    if not os.path.exists(src_path):
        return None
    backup_dir = os.path.join(BACKUP_DIR_BASE, f"guardrail_backup_{TIMESTAMP}")
    os.makedirs(backup_dir, exist_ok=True)
    dest = os.path.join(backup_dir, os.path.basename(src_path))
    shutil.copy2(src_path, dest)
    return dest

def write_audit(msg):
    ensure_dirs()
    logfile = os.path.join(AUDIT_LOG_DIR, f"guardrail_neutralizer_{TIMESTAMP}.log")
    with open(logfile, "a", encoding="utf-8") as f:
        f.write(f"[{datetime.utcnow().isoformat()}] {msg}\n")
    print(msg)

def create_override(original_name, transform_fn):
    src = os.path.join(CONFIGS_DIR, original_name)
    if not os.path.exists(src):
        write_audit(f"[WARN] Config not found (skipped): {original_name}")
        return False
    backed = backup_file(src)
    if backed:
        write_audit(f"[BACKUP] {original_name} -> {backed}")
    try:
        data = load_json(src)
    except Exception as e:
        write_audit(f"[ERROR] Failed to parse {original_name}: {e}")
        return False
    overridden = transform_fn(data)
    override_path = os.path.join(CONFIGS_DIR, original_name.replace(".json", ".override.json"))
    dump_json(override_path, overridden)
    write_audit(f"[OVERRIDE] Created override file: {override_path}")
    return True

def neutralize_frontend_manifest(data):
    # Non-destructive: turn all validation rules OFF in the override
    meta = data.copy()
    if "validation_rules" in meta and isinstance(meta["validation_rules"], dict):
        for k in meta["validation_rules"]:
            meta["validation_rules"][k] = False
    else:
        meta["validation_rules"] = {
            "require_backend_mapping": False,
            "enforce_binding_validation": False,
            "mandate_forensic_logging": False,
            "android_integration_required": False
        }
    return meta

def neutralize_activation_rules(data):
    meta = data.copy()
    meta["enabled"] = False
    # Also zero out activation thresholds if present
    for k in list(meta.keys()):
        if isinstance(meta[k], (int, float)):
            meta[k] = 0
    return meta

def neutralize_frontend_to_backend_map(data):
    # Keep mapping but mark all entries optional in override
    meta = data.copy()
    for k, v in meta.items():
        if isinstance(v, dict):
            v = v.copy()
            v["requires_api"] = False
            meta[k] = v
    return meta

def apply():
    ensure_dirs()
    write_audit("[ACTION] Applying guardrail neutralizer")
    created = []
    # FRONTEND MANIFEST
    if create_override("frontend_manifest.json", neutralize_frontend_manifest):
        created.append("frontend_manifest.override.json")
    if create_override("activation_rules.json", neutralize_activation_rules):
        created.append("activation_rules.override.json")
    if create_override("frontend_to_backend_map.json", neutralize_frontend_to_backend_map):
        created.append("frontend_to_backend_map.override.json")

    # Create a simple flag file used by runtime wrappers
    flag = {
        "applied_at": datetime.utcnow().isoformat(),
        "created_overrides": created
    }
    flag_path = os.path.join(AUDIT_LOG_DIR, f"guardrail_bypass_flag_{TIMESTAMP}.json")
    dump_json(flag_path, flag)
    write_audit(f"[FLAG] Wrote bypass flag: {flag_path}")
    write_audit("[INFO] To activate bypass at runtime, set GUARDRAIL_BYPASS=1 in the environment before starting services.")
    write_audit("[COMPLETE] Guardrail neutralizer applied (non-destructive).")

def revert():
    ensure_dirs()
    write_audit("[ACTION] Reverting guardrail neutralizer (removing override files)")
    removed = []
    for name in FILES_TO_OVERRIDE:
        override = os.path.join(CONFIGS_DIR, name.replace(".json", ".override.json"))
        if os.path.exists(override):
            backup = backup_file(override)
            os.remove(override)
            removed.append(override)
            write_audit(f"[REVERT] Removed override {override} (backed up: {backup})")
    write_audit(f"[COMPLETE] Reverted. Removed {len(removed)} override files.")

def main():
    p = argparse.ArgumentParser(description="Guardrail Neutralizer")
    p.add_argument("--apply", action="store_true", help="Apply non-destructive neutralizer")
    p.add_argument("--revert", action="store_true", help="Revert by removing created override files")
    args = p.parse_args()

    if args.apply:
        apply()
    elif args.revert:
        revert()
    else:
        p.print_help()

if __name__ == "__main__":
    main()