#!/bin/bash

# ==================================================
# Minecraft Universal Engine - Enterprise Core
# ==================================================

set -e

ENGINE_VERSION="2.0.0"

WORKDIR="$(pwd)"

if [ ! -d "$WORKDIR/core" ]; then
    echo "[FATAL] Engine core directory not found."
    echo "Current directory: $WORKDIR"
    exit 1
fi

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

source core/logger.sh        || { echo "[FATAL] Logger module missing."; exit 1; }
source core/version.sh       || { log_error "Version module missing."; exit 1; }
source core/state.sh         || { log_error "State module missing."; exit 1; }
source core/compatibility.sh || { log_error "Compatibility module missing."; exit 1; }
source core/policy.sh        || { log_error "Policy module missing."; exit 1; }
source core/java.sh          || { log_error "Java module missing."; exit 1; }

log_info "Engine boot starting..."
log_info "Server Type: $SERVER_TYPE"
log_info "Requested Version: $MINECRAFT_VERSION"
log_info "Policy: $CHANGE_POLICY"
log_info "Update Mode: $UPDATE_MODE"
log_info "Force Override: $FORCE_CHANGE"

# ===========================
# Initialize Systems
# ===========================

initialize_version_system      # Resolves TARGET_VERSION
initialize_state_system        # Loads PREVIOUS state
classify_change                # Determines CHANGE_TYPE
evaluate_policy                # Applies policy rules
initialize_java_system         # Validates Java compatibility

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
# Apply Changes If Needed
# ===========================

if [ "$CHANGE_TYPE" = "first_install" ]; then

    log_info "First installation detected."

    install_engine
    save_current_state

elif [ "$VERSION_CHANGED" = "true" ]; then

    log_info "Version change detected."

    if [ "$UPDATE_MODE" = "clean" ]; then
        log_warn "Executing clean environment procedure."
        clean_environment
    fi

    install_engine
    save_current_state

else

    log_info "No version change detected. Starting normally."

fi

# ===========================
# Start Server
# ===========================

log_info "Starting $ENGINE_PROFILE $TARGET_VERSION"

start_server
