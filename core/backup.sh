#!/bin/bash

create_backup() {

    if [ "$AUTO_BACKUP" != "true" ]; then
        log_info "Auto backup disabled."
        return
    fi

    if [ "$FIRST_INSTALL" = "true" ]; then
        log_info "First installation. Backup not required."
        return
    fi

    if [ "$CHANGE_TYPE" = "no_change" ]; then
        return
    fi

    TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
    BACKUP_DIR="backups"
    BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"

    mkdir -p "$BACKUP_DIR"

    log_info "Creating backup: $BACKUP_NAME"

    BACKUP_TARGETS=()

    # Worlds
    for dir in world world_nether world_the_end; do
        if [ -d "$dir" ]; then
            BACKUP_TARGETS+=("$dir")
        fi
    done

    # Server configs
    for file in server.properties eula.txt ops.json whitelist.json; do
        if [ -f "$file" ]; then
            BACKUP_TARGETS+=("$file")
        fi
    done

    # Paper plugins
    if [ -d "plugins" ]; then
        BACKUP_TARGETS+=("plugins")
    fi

    # Modded folders
    if [ -d "mods" ]; then
        BACKUP_TARGETS+=("mods")
    fi

    if [ -d "config" ]; then
        BACKUP_TARGETS+=("config")
    fi

    if [ -d "libraries" ]; then
        BACKUP_TARGETS+=("libraries")
    fi

    if [ ${#BACKUP_TARGETS[@]} -eq 0 ]; then
        log_warn "Nothing found to backup."
        return
    fi

    tar -czf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_TARGETS[@]}"

    if [ $? -eq 0 ]; then
        log_info "Backup created successfully."
    else
        log_error "Backup failed."
        exit 1
    fi
}
