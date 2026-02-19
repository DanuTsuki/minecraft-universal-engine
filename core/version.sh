#!/bin/bash

resolve_target_version() {

    if [ "$MINECRAFT_VERSION" = "latest" ]; then
        log_info "Resolving latest version from Paper API..."

        TARGET_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')

        if [ -z "$TARGET_VERSION" ] || [ "$TARGET_VERSION" = "null" ]; then
            log_error "Failed to resolve latest version."
            exit 1
        fi

        log_info "Resolved latest version: $TARGET_VERSION"
    else
        TARGET_VERSION="$MINECRAFT_VERSION"
    fi
}

parse_version_components() {

    IFS='.' read -r MC_MAJOR MC_MINOR MC_PATCH <<< "$TARGET_VERSION"

    if [ -z "$MC_PATCH" ]; then
        MC_PATCH="0"
    fi
}

detect_engine_era() {

    ENGINE_ERA="modern"

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

    log_info "Resolving target version..."
    resolve_target_version

    log_info "Parsing version components..."
    parse_version_components

    log_info "Detecting engine era..."
    detect_engine_era

    log_info "Detecting modded flag..."
    detect_modded_flag

    log_info "Determining engine profile..."
    detect_engine_profile

    log_info "Target Version: $TARGET_VERSION"
    log_info "Engine Profile: $ENGINE_PROFILE"
    log_info "Engine Era: $ENGINE_ERA"
    log_info "Modded: $IS_MODDED"
}
