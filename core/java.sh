#!/bin/bash

detect_current_java() {

    JAVA_VERSION_RAW=$(java -version 2>&1 | head -n 1)

    # Extract version number
    if [[ "$JAVA_VERSION_RAW" =~ \"([0-9]+) ]]; then
        CURRENT_JAVA_VERSION="${BASH_REMATCH[1]}"
    else
        log_warn "Unable to detect Java version."
        CURRENT_JAVA_VERSION="unknown"
    fi

    log_info "Detected Java version: $CURRENT_JAVA_VERSION"
}

determine_required_java() {

    REQUIRED_JAVA_VERSION="17"  # default modern

    if [ "$MC_MINOR" -le 16 ]; then
        REQUIRED_JAVA_VERSION="8"
    fi

    if [ "$MC_MINOR" -eq 17 ]; then
        REQUIRED_JAVA_VERSION="16"
    fi

    if [ "$MC_MINOR" -ge 18 ] && [ "$MC_MINOR" -le 20 ]; then
        REQUIRED_JAVA_VERSION="17"
    fi

    if [ "$MC_MINOR" -ge 21 ]; then
        REQUIRED_JAVA_VERSION="21"
    fi

    # Forge legacy override
    if [ "$ENGINE_PROFILE" = "forge_legacy" ]; then
        REQUIRED_JAVA_VERSION="8"
    fi

    log_info "Required Java version: $REQUIRED_JAVA_VERSION"
}

validate_java_compatibility() {

    if [ "$CURRENT_JAVA_VERSION" = "unknown" ]; then
        return
    fi

    if [ "$CURRENT_JAVA_VERSION" -ne "$REQUIRED_JAVA_VERSION" ]; then

        log_warn "Java version mismatch detected."
        log_warn "Current: $CURRENT_JAVA_VERSION"
        log_warn "Required: $REQUIRED_JAVA_VERSION"

        if [ "$CHANGE_POLICY" = "strict" ]; then
            log_error "Strict policy blocks mismatched Java version."
            exit 1
        fi

        if [ "$CHANGE_POLICY" = "balanced" ]; then
            log_warn "Balanced policy allows start but may cause crash."
        fi

        if [ "$CHANGE_POLICY" = "permissive" ]; then
            log_warn "Permissive mode: proceeding despite mismatch."
        fi
    else
        log_info "Java version compatible."
    fi
}

initialize_java_system() {

    detect_current_java
    determine_required_java
    validate_java_compatibility
}
