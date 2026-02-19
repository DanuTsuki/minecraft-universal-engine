#!/bin/bash

STATE_FILE=".engine_state.json"

load_previous_state() {

    FIRST_INSTALL="false"

    if [ ! -f "$STATE_FILE" ]; then
        log_info "No previous engine state found. First installation detected."
        FIRST_INSTALL="true"
        return
    fi

    PREV_ENGINE=$(jq -r '.engine' "$STATE_FILE")
    PREV_PROFILE=$(jq -r '.profile' "$STATE_FILE")
    PREV_VERSION=$(jq -r '.version' "$STATE_FILE")
    PREV_ERA=$(jq -r '.era' "$STATE_FILE")

    log_info "Previous Engine: $PREV_ENGINE"
    log_info "Previous Profile: $PREV_PROFILE"
    log_info "Previous Version: $PREV_VERSION"
    log_info "Previous Era: $PREV_ERA"
}

detect_state_changes() {

    ENGINE_CHANGED="false"
    PROFILE_CHANGED="false"
    VERSION_CHANGED="false"
    ERA_CHANGED="false"

    if [ "$FIRST_INSTALL" = "true" ]; then
        return
    fi

    if [ "$SERVER_TYPE" != "$PREV_ENGINE" ]; then
        ENGINE_CHANGED="true"
    fi

    if [ "$ENGINE_PROFILE" != "$PREV_PROFILE" ]; then
        PROFILE_CHANGED="true"
    fi

    if [ "$MINECRAFT_VERSION" != "$PREV_VERSION" ]; then
        VERSION_CHANGED="true"
    fi

    if [ "$ENGINE_ERA" != "$PREV_ERA" ]; then
        ERA_CHANGED="true"
    fi

    log_info "Change Detection:"
    log_info "ENGINE_CHANGED=$ENGINE_CHANGED"
    log_info "PROFILE_CHANGED=$PROFILE_CHANGED"
    log_info "VERSION_CHANGED=$VERSION_CHANGED"
    log_info "ERA_CHANGED=$ERA_CHANGED"
}

save_current_state() {

    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "$STATE_FILE" <<EOF
{
  "engine": "$SERVER_TYPE",
  "profile": "$ENGINE_PROFILE",
  "version": "$MINECRAFT_VERSION",
  "era": "$ENGINE_ERA",
  "last_update_mode": "$UPDATE_MODE",
  "updated_at": "$TIMESTAMP"
}
EOF

    log_info "Engine state saved."
}

initialize_state_system() {

    load_previous_state
    detect_state_changes
}
