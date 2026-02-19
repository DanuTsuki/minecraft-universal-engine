#!/bin/bash

# ==================================================
# Minecraft Universal Engine - Enterprise Core
# ==================================================

cd /mnt/server || exit 1

ENGINE_VERSION="2.0.0"

echo "================================================"
echo " Minecraft Universal Engine v$ENGINE_VERSION"
echo "================================================"

# ===========================
# Load Environment Variables
# ===========================

SERVER_TYPE="${SERVER_TYPE}"
MINECRAFT_VERSION="${MINECRAFT_VERSION}"
CHANGE_POLICY="${CHANGE_POLICY:-balanced}"
UPDATE_MODE="${UPDATE_MODE:-preserve}"
AUTO_BACKUP="${AUTO_BACKUP:-true}"
FORCE_CHANGE="${FORCE_CHANGE:-false}"

# ===========================
# Validate Required Variables
# ===========================

if [ -z "$SERVER_TYPE" ]; then
    echo "[FATAL] SERVER_TYPE not defined."
    exit 1
fi

if [ -z "$MINECRAFT_VERSION" ]; then
    echo "[FATAL] MINECRAFT_VERSION not defined."
    exit 1
fi

# ===========================
# Load Core Modules
# ===========================

source core/logger.sh || { echo "Logger module missing."; exit 1; }
source core/version.sh || { log_error "Version module missing."; exit 1; }
source core/state.sh || { log_error "State module missing."; exit 1; }
source core/compatibility.sh || { log_error "Compatibility module missing."; exit 1; }
source core/policy.sh || { log_error "Policy module missing."; exit 1; }
source core/backup.sh || { log_error "Backup module missing."; exit 1; }
source core/java.sh || { log_error "Java module missing."; exit 1; }

log_info "Engine boot starting..."
log_info "Server Type: $SERVER_TYPE"
log_info "Minecraft Version: $MINECRAFT_VERSION"
log_info "Policy: $CHANGE_POLICY"
log_info "Update Mode: $UPDATE_MODE"

# ===========================
# Initialize Systems
# ===========================

initialize_version_system
initialize_state_system
classify_change
log_compatibility_summary
evaluate_policy
log_policy_summary
initialize_java_system

# ===========================
# Backup if Needed
# ===========================

create_backup

# ===========================
# Load Engine Module
# ===========================

ENGINE_SCRIPT="core/engines/${ENGINE_PROFILE}.sh"

if [ ! -f "$ENGINE_SCRIPT" ]; then
    log_error "Engine profile module not found: $ENGINE_PROFILE"
    exit 1
fi

source "$ENGINE_SCRIPT"

# ===========================
# Clean if Required
# ===========================

if [ "$UPDATE_MODE" = "clean" ]; then
    log_warn "Executing clean environment procedure."
    clean_environment
fi

# ===========================
# Install / Update Engine
# ===========================

install_engine

# ===========================
# Save State
# ===========================

save_current_state

# ===========================
# Start Server
# ===========================

start_server
