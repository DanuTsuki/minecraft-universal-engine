#!/bin/bash

install_engine() {
    log_info "Iniciando instalación de Fabric Meta Engine para Minecraft $TARGET_VERSION"

    log_info "Consultando API de Fabric Meta (stable tracks)..."
    
    # Extraemos las últimas versiones estables del Loader y del Installer
    LOADER_VERSION=$(curl -s https://meta.fabricmc.net/v2/versions/loader | jq -r '[.[] | select(.stable==true)][0].version')
    INSTALLER_VERSION=$(curl -s https://meta.fabricmc.net/v2/versions/installer | jq -r '[.[] | select(.stable==true)][0].version')

    if [ -z "$LOADER_VERSION" ] || [ "$LOADER_VERSION" = "null" ] || [ -z "$INSTALLER_VERSION" ] || [ "$INSTALLER_VERSION" = "null" ]; then
        log_error "Fallo al obtener la metadata estructural de Fabric."
        exit 1
    fi

    log_info "Fabric Loader: $LOADER_VERSION | Installer: $INSTALLER_VERSION"

    # Construcción de la URL del endpoint que genera el jar pre-ensamblado
    FABRIC_URL="https://meta.fabricmc.net/v2/versions/loader/${TARGET_VERSION}/${LOADER_VERSION}/${INSTALLER_VERSION}/server/jar"
    
    log_info "Descargando binario unificado fabric-server.jar..."
    curl -s -S -L -o fabric-server.jar "$FABRIC_URL"

    if [ $? -ne 0 ] || [ ! -f "fabric-server.jar" ]; then
        log_error "La descarga del binario de Fabric ha fallado."
        exit 1
    fi

    log_info "Instalación de Fabric completada."
}

clean_environment() {
    log_warn "Ejecutando limpieza de entorno para Fabric."
    
    rm -rf mods config .fabric fabric-server.jar libraries
}

start_server() {
    log_info "Iniciando servidor Fabric Loader."

    # Fabric se auto-gestiona a través de su propio .jar unificado
    java -Xms128M -XX:MaxRAMPercentage=95.0 \
         -Dterminal.jline=false \
         -Dterminal.ansi=true \
         -jar fabric-server.jar nogui
}