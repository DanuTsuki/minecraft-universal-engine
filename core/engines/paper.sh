#!/bin/bash

install_engine() {

    log_info "Installing Paper $MINECRAFT_VERSION"

    # Detect latest if needed
    if [ "$MINECRAFT_VERSION" = "latest" ]; then
        MINECRAFT_VERSION=$(curl -s https://api.papermc.io/v2/projects/paper | jq -r '.versions[-1]')
        log_info "Resolved latest version: $MINECRAFT_VERSION"
    fi

    BUILD=$(curl -s https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION | jq -r '.builds[-1]')

    if [ -z "$BUILD" ] || [ "$BUILD" = "null" ]; then
        log_error "Unable to fetch Paper build."
        exit 1
    fi

    JAR_NAME="paper-${MINECRAFT_VERSION}-${BUILD}.jar"

    log_info "Downloading Paper build $BUILD"

    curl -o server.jar \
        https://api.papermc.io/v2/projects/paper/versions/$MINECRAFT_VERSION/builds/$BUILD/downloads/$JAR_NAME

    if [ $? -ne 0 ]; then
        log_error "Paper download failed."
        exit 1
    fi

    log_info "Paper installed successfully."
}

clean_environment() {

    log_info "Cleaning environment for Paper."

    rm -rf libraries mods config
}

start_server() {

    log_info "Starting Paper server."

    java -Xms128M -XX:MaxRAMPercentage=95.0 \
         -Dterminal.jline=false \
         -Dterminal.ansi=true \
         -jar server.jar nogui
}
