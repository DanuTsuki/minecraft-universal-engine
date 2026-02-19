#!/bin/bash

install_engine() {

    log_info "Installing Vanilla $MINECRAFT_VERSION"

    MANIFEST=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json)

    if [ "$MINECRAFT_VERSION" = "latest" ]; then
        VERSION_URL=$(echo "$MANIFEST" | jq -r '.versions[] | select(.type=="release") | .url' | head -n1)
    else
        VERSION_URL=$(echo "$MANIFEST" | jq -r --arg VERSION "$MINECRAFT_VERSION" \
            '.versions[] | select(.id==$VERSION) | .url')
    fi

    if [ -z "$VERSION_URL" ] || [ "$VERSION_URL" = "null" ]; then
        log_error "Vanilla version not found."
        exit 1
    fi

    SERVER_URL=$(curl -s "$VERSION_URL" | jq -r '.downloads.server.url')

    curl -o server.jar "$SERVER_URL"

    if [ $? -ne 0 ]; then
        log_error "Vanilla download failed."
        exit 1
    fi

    log_info "Vanilla installed successfully."
}

clean_environment() {

    log_info "Cleaning modded remnants for Vanilla."

    rm -rf mods config libraries
}

start_server() {

    log_info "Starting Vanilla server."

    java -Xms128M -XX:MaxRAMPercentage=95.0 \
         -Dterminal.jline=false \
         -Dterminal.ansi=true \
         -jar server.jar nogui
}
