#!/bin/bash
# UserLAnd Configuration Manager - Android 10+ Compatible
# Author: spiralgang
# Version: 1.0.0

set -e

# ======= CONFIGURATION =======
BACKUP_DIR="$HOME/.ul_config_backups/$(date +%Y%m%d_%H%M%S)"
CONFIG_PATHS=(
  "$HOME/userland"
  "$HOME/.config/userland" 
  "$HOME/.local/share/userland"
)
OWNER_NAME="spiralgang"
LOG_FILE="$HOME/ul_config_manager.log"

# ======= INITIALIZATION =======
mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date +%Y-%m-%d\ %H:%M:%S)] Starting UserLAnd configuration manager"

# Check for required tools
MISSING_DEPS=0
for cmd in jq sed grep find xargs; do
  if ! command -v $cmd &> /dev/null; then
    echo "ERROR: Required tool '$cmd' not found"
    MISSING_DEPS=1
  fi
done

if [ $MISSING_DEPS -eq 1 ]; then
  echo "Installing missing dependencies..."
  apt-get update -qq && apt-get install -y jq sed grep findutils 
fi

# ======= UTILITY FUNCTIONS =======
backup_file() {
  local src="$1"
  local rel_path="${src#$HOME/}"
  local dst="$BACKUP_DIR/$rel_path"
  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
}

log_action() {
  echo "[$(date +%Y-%m-%d\ %H:%M:%S)] $1"
}

# ======= FILE PROCESSORS =======
process_json() {
  local file="$1"
  
  # Security policy JSON adjustments
  if grep -q "enforcement" "$file"; then
    backup_file "$file"
    # Update security policy to use owner name
    jq ".conditions[0].pattern = \"$OWNER_NAME\" | 
        .enforcement = \"active\"" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
    log_action "Updated security policy in $file"
  fi
  
  # App configuration JSON
  if grep -q "\"apps\"\\|\"filesystem\"" "$file"; then
    backup_file "$file"
    jq '.autoUpdate = true | 
        .preferredShell = "/bin/zsh" | 
        .androidCompat = 10' "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
    log_action "Updated app configuration in $file"
  fi
}

process_toml() {
  local file="$1"
  backup_file "$file"
  
  # Package configurations
  if grep -q "\\[package\\]" "$file"; then
    sed -i "s/edition = \"[0-9]*\"/edition = \"2021\"/g" "$file"
    sed -i "s/tokio = { version = \"[0-9.]*\"/tokio = { version = \"1.2\"/g" "$file"
    log_action "Updated package configuration in $file"
  fi
  
  # Dependencies update for Android 10 compatibility
  if grep -q "\\[dependencies\\]" "$file"; then
    # Ensure compatible dependencies
    sed -i '/\[dependencies\]/a android_logger = "0.11"' "$file"
    log_action "Added Android 10 compatibility in $file"
  fi
}

process_xml() {
  local file="$1"
  backup_file "$file"
  
  # Android manifest adjustments
  if grep -q "<manifest" "$file"; then
    sed -i 's/android:theme="@android:style\/Theme.Black.NoTitleBar.Fullscreen"/android:theme="@android:style\/Theme.DeviceDefault"/g' "$file"
    sed -i "s/android:label=\"[^\"]*\"/android:label=\"UL-$OWNER_NAME\"/g" "$file"
    log_action "Updated Android manifest in $file"
  fi
}

process_conf() {
  local file="$1"
  backup_file "$file"
  
  # System configuration
  if grep -q "DSHELL\\|DIR_MODE" "$file"; then
    sed -i 's/DSHELL=\/bin\/bash/DSHELL=\/bin\/zsh/g' "$file"
    sed -i 's/DIR_MODE=0750/DIR_MODE=0755/g' "$file"
    log_action "Updated system configuration in $file"
  fi
  
  # User configuration
  if grep -q "USERGROUPS\\|ADD_EXTRA_GROUPS" "$file"; then
    sed -i 's/#ADD_EXTRA_GROUPS=1/ADD_EXTRA_GROUPS=1/g' "$file"
    sed -i 's/#EXTRA_GROUPS=/EXTRA_GROUPS="audio video net_admin"/g' "$file"
    log_action "Updated user group configuration in $file"
  fi
}

# ======= MAIN EXECUTION =======
FILES_PROCESSED=0

# Find and process configuration files
for path in "${CONFIG_PATHS[@]}"; do
  if [ ! -d "$path" ]; then
    log_action "Directory not found: $path - skipping"
    continue
  fi
  
  log_action "Scanning directory: $path"
  
  # Process JSON files
  find "$path" -type f -name "*.json" -print0 | while IFS= read -r -d '' file; do
    process_json "$file"
    ((FILES_PROCESSED++))
  done
  
  # Process TOML files
  find "$path" -type f \( -name "*.toml" -o -name "Cargo.toml" \) -print0 | while IFS= read -r -d '' file; do
    process_toml "$file"
    ((FILES_PROCESSED++))
  done
  
  # Process XML files
  find "$path" -type f -name "*.xml" -print0 | while IFS= read -r -d '' file; do
    process_xml "$file"
    ((FILES_PROCESSED++))
  done
  
  # Process config files
  find "$path" -type f -name "*.conf" -print0 | while IFS= read -r -d '' file; do
    process_conf "$file"
    ((FILES_PROCESSED++))
  done
done

# Update global profile if exists
PROFILE_FILE="$HOME/.userland_profile"
if [ -f "$PROFILE_FILE" ]; then
  backup_file "$PROFILE_FILE"
  
  # Add custom environment settings if not already present
  if ! grep -q "ANDROID_COMPAT=" "$PROFILE_FILE"; then
    cat >> "$PROFILE_FILE" << EOF

# UserLAnd Android 10 compatibility settings
export ANDROID_COMPAT=10
export PROOT_NO_SECCOMP=1
export PATH=\$HOME/bin:\$PATH
export SHELL=/bin/zsh
EOF
    log_action "Updated UserLAnd profile with Android 10 compatibility settings"
  fi
fi

# ======= SUMMARY =======
log_action "Configuration update complete"
log_action "Files processed: $FILES_PROCESSED"
log_action "Backups created in: $BACKUP_DIR"

# Execute post-configuration hook if exists
if [ -x "$HOME/bin/ul_config_hook.sh" ]; then
  log_action "Running post-configuration hook"
  "$HOME/bin/ul_config_hook.sh"
fi

echo "UserLAnd configuration completed successfully"