#!/bin/bash

detect_version_components() {

    if [ "$MINECRAFT_VERSION" = "latest" ]; then
        log_warn "Version is set to latest. Exact era detection may be limited."
        MC_MAJOR="1"
        MC_MINOR="20"
        MC_PATCH="0"
        return
    fi

    IFS='.' read -r MC_MAJOR MC_MINOR MC_PATCH <<< "$MINECRAFT_VERSION"

    if [ -z "$MC_PATCH" ]; then
        MC_PATCH="0"
    fi
}

detect_engine_era() {

    # Default
    ENGINE_ERA="modern"

    # Era classification based on Minecraft minor version
    if [ "$MC_MINOR" -le 12 ]; then
        ENGINE_ERA="legacy"
    elif [ "$MC_MINOR" -le 16 ]; then
        ENGINE_ERA="transitional"
    else
        ENGINE_ERA="modern"
    fi
}

detect_modded_flag() {

    case "$SERVER_TYPE" in
        forge|fabric|sponge)
            IS_MODDED="true"
            ;;
        *)
            IS_MODDED="false"
            ;;
    esac
}

detect_engine_profile() {

    case "$SERVER_TYPE" in

        paper)
            ENGINE_PROFILE="paper"
            ;;

        vanilla)
            ENGINE_PROFILE="vanilla"
            ;;

        forge)
            if [ "$ENGINE_ERA" = "legacy" ]; then
                ENGINE_PROFILE="forge_legacy"
            else
                ENGINE_PROFILE="forge_modern"
            fi
            ;;

        fabric)
            ENGINE_PROFILE="fabric"
            ;;

        sponge)
            ENGINE_PROFILE="sponge"
            ;;

        *)
            log_error "Unknown SERVER_TYPE: $SERVER_TYPE"
            exit 1
            ;;
    esac
}

initialize_version_system() {

    log_info "Detecting version components..."
    detect_version_components

    log_info "Detecting engine era..."
    detect_engine_era

    log_info "Detecting modded flag..."
    detect_modded_flag

    log_info "Determining engine profile..."
    detect_engine_profile

    log_info "Engine Profile: $ENGINE_PROFILE"
    log_info "Engine Era: $ENGINE_ERA"
    log_info "Modded: $IS_MODDED"
}
