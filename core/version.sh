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

    # ── Snapshot: 25w14a, 24w46a ──────────────────────────────────────────────
    if [[ "$TARGET_VERSION" =~ ^[0-9]{2}w[0-9]{2}[a-z]+$ ]]; then
        IS_SNAPSHOT="true"
        # Treat all snapshots as modern (1.21+) so era/java logic works correctly
        MC_MAJOR="1"
        MC_MINOR="99"
        MC_PATCH="0"
        MC_BASE="$TARGET_VERSION"
        log_info "Snapshot version detected ($TARGET_VERSION) — treating as modern era"
        return
    fi

    IS_SNAPSHOT="false"

    # ── Forge build: 1.21.1-52.1.14 ──────────────────────────────────────────
    # ── NeoForge short build: 21.1.14 (no leading "1.") ──────────────────────
    # Strip the part after the dash (Forge suffix) to get the pure MC version
    MC_BASE="${TARGET_VERSION%%-*}"

    IFS='.' read -r MC_MAJOR MC_MINOR MC_PATCH <<< "$MC_BASE"

    # NeoForge short builds look like "21.1.14" — MC_MAJOR would be "21"
    # which is not a valid Minecraft major version, so remap it.
    # e.g.  21.1.14  → MC_MAJOR=1  MC_MINOR=21  MC_PATCH=1
    if [[ "$MC_MAJOR" =~ ^[2-9][0-9]+$ ]]; then
        MC_PATCH="$MC_MINOR"
        MC_MINOR="$MC_MAJOR"
        MC_MAJOR="1"
    fi

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
        forge|neoforge|fabric|sponge)
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

        neoforge)
            ENGINE_PROFILE="neoforge"
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