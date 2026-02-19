#!/bin/bash

classify_change() {

    CHANGE_TYPE="none"
    RISK_LEVEL="low"
    RECOMMENDED_UPDATE_MODE="preserve"
    BLOCK_OPERATION="false"

    if [ "$FIRST_INSTALL" = "true" ]; then
        CHANGE_TYPE="first_install"
        return
    fi

    if [ "$ENGINE_CHANGED" = "false" ] && \
       [ "$VERSION_CHANGED" = "false" ]; then
        CHANGE_TYPE="no_change"
        return
    fi

    # ==============================
    # Detect downgrade
    # ==============================

    if [ "$VERSION_CHANGED" = "true" ]; then

        if [ "$MC_MINOR" -lt "$(echo $PREV_VERSION | cut -d'.' -f2)" ]; then
            CHANGE_TYPE="downgrade"
            RISK_LEVEL="critical"
            RECOMMENDED_UPDATE_MODE="clean"
            BLOCK_OPERATION="true"
            return
        fi
    fi

    # ==============================
    # Engine Switch
    # ==============================

    if [ "$ENGINE_CHANGED" = "true" ]; then
        CHANGE_TYPE="engine_switch"
        RISK_LEVEL="high"
        RECOMMENDED_UPDATE_MODE="clean"
        return
    fi

    # ==============================
    # Era Change (Forge generations)
    # ==============================

    if [ "$ERA_CHANGED" = "true" ]; then
        CHANGE_TYPE="era_change"
        RISK_LEVEL="critical"
        RECOMMENDED_UPDATE_MODE="clean"
        BLOCK_OPERATION="true"
        return
    fi

    # ==============================
    # Modded Version Change
    # ==============================

    if [ "$IS_MODDED" = "true" ] && \
       [ "$VERSION_CHANGED" = "true" ]; then

        CHANGE_TYPE="modded_version_change"
        RISK_LEVEL="high"
        RECOMMENDED_UPDATE_MODE="clean"
        return
    fi

    # ==============================
    # Safe update (vanilla/paper minor)
    # ==============================

    if [ "$VERSION_CHANGED" = "true" ]; then
        CHANGE_TYPE="safe_update"
        RISK_LEVEL="medium"
        RECOMMENDED_UPDATE_MODE="preserve"
        return
    fi
}

log_compatibility_summary() {

    log_info "Change Type: $CHANGE_TYPE"
    log_info "Risk Level: $RISK_LEVEL"
    log_info "Recommended UPDATE_MODE: $RECOMMENDED_UPDATE_MODE"
    log_info "Block Operation: $BLOCK_OPERATION"
}
