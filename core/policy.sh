#!/bin/bash

evaluate_policy() {

    ALLOW_OPERATION="true"
    SHOW_WARNING="false"
    FORCE_CLEAN="false"

    # =============================
    # Strict hard block (technical)
    # =============================

    if [ "$BLOCK_OPERATION" = "true" ]; then
        log_error "Operation blocked due to critical compatibility violation."
        exit 1
    fi

    # =============================
    # Balanced Policy
    # =============================

    if [ "$CHANGE_POLICY" = "balanced" ]; then

        case "$CHANGE_TYPE" in

            first_install)
                return
                ;;

            no_change)
                return
                ;;

            safe_update)
                return
                ;;

            engine_switch)
                SHOW_WARNING="true"
                FORCE_CLEAN="true"
                ;;

            modded_version_change)
                SHOW_WARNING="true"

                if [ "$UPDATE_MODE" != "clean" ]; then
                    log_warn "Modded version change detected."
                    log_warn "Recommended UPDATE_MODE=clean."
                fi
                ;;

            era_change)
                log_error "Era change detected. Clean installation required."
                exit 1
                ;;

            downgrade)
                log_error "Downgrade detected. Operation blocked."
                exit 1
                ;;

        esac
    fi

    # =============================
    # Strict Policy
    # =============================

    if [ "$CHANGE_POLICY" = "strict" ]; then

        case "$CHANGE_TYPE" in

            first_install|no_change)
                return
                ;;

            *)
                log_error "Strict policy blocks this change type: $CHANGE_TYPE"
                exit 1
                ;;

        esac
    fi

    # =============================
    # Permissive Policy
    # =============================

    if [ "$CHANGE_POLICY" = "permissive" ]; then

        if [ "$RISK_LEVEL" = "high" ] || \
           [ "$RISK_LEVEL" = "critical" ]; then

            SHOW_WARNING="true"

            log_warn "Permissive mode: High risk change allowed."
            log_warn "Proceeding despite risk."
        fi
    fi

    # =============================
    # Apply UPDATE_MODE enforcement
    # =============================

    if [ "$FORCE_CLEAN" = "true" ]; then
        if [ "$UPDATE_MODE" != "clean" ]; then
            log_warn "Engine switch requires clean mode."
            log_warn "Overriding UPDATE_MODE to clean."
            UPDATE_MODE="clean"
        fi
    fi
}

log_policy_summary() {

    log_info "Policy Evaluation Complete:"
    log_info "Allow Operation: $ALLOW_OPERATION"
    log_info "Show Warning: $SHOW_WARNING"
    log_info "Force Clean: $FORCE_CLEAN"
}
