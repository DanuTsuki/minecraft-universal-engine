#!/bin/bash

install_engine() {
    log_info "Iniciando instalación de Forge Moderno para Minecraft $TARGET_VERSION"

    # Obtener el índice de versiones de Forge (Slim Promo)
    log_info "Resolviendo build recomendado/latest de Forge..."
    FORGE_VERSION=$(curl -s https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json | jq -r --arg VER "$TARGET_VERSION" '.promos[$VER + "-recommended"] // .promos[$VER + "-latest"]')

    if [ -z "$FORGE_VERSION" ] || [ "$FORGE_VERSION" = "null" ]; then
        log_error "No se pudo resolver una versión de Forge para Minecraft $TARGET_VERSION"
        exit 1
    fi

    log_info "Build de Forge seleccionado: $FORGE_VERSION"
    
    INSTALLER_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${TARGET_VERSION}-${FORGE_VERSION}/forge-${TARGET_VERSION}-${FORGE_VERSION}-installer.jar"
    
    log_info "Descargando instalador de Forge..."
    curl -s -S -L -o forge-installer.jar "$INSTALLER_URL"

    if [ $? -ne 0 ] || [ ! -f "forge-installer.jar" ]; then
        log_error "Fallo crítico en la descarga del instalador de Forge."
        exit 1
    fi

    log_info "Ejecutando instalador de dependencias de Forge (Server Mode)..."
    # Forzamos la ejecución usando el Java enrutado para evitar conflictos de memoria
    "$JAVA_BIN" -jar forge-installer.jar --installServer > install_log.txt 2>&1
    
    if [ ! -d "libraries/net/minecraftforge" ]; then
        log_error "Error: La carpeta de librerías no se generó. Revisa install_log.txt"
        exit 1
    fi

    if [ $? -ne 0 ]; then
        log_error "El instalador de Forge devolvió un error durante la extracción."
        exit 1
    fi

    # Limpieza inmediata para optimizar almacenamiento del nodo
    rm -f forge-installer.jar forge-installer.jar.log
    log_info "Árbol de dependencias de Forge instalado con éxito."
}

clean_environment() {
    log_warn "Ejecutando limpieza de entorno restrictiva para Forge."
    
    # Forge moderno es altamente sensible a conflictos en el Classpath
    rm -rf libraries mods config user_jvm_args.txt run.sh run.bat
}

start_server() {
    log_info "Iniciando Forge mediante mapeo de argumentos modernos."

    # Mapeo dinámico del archivo de argumentos de Unix generado por Forge
    # Esto es necesario porque la ruta exacta depende de la versión instalada
    UNIX_ARGS_FILE=$(find libraries/net/minecraftforge/forge -name "unix_args.txt" | head -n 1)

    if [ -n "$UNIX_ARGS_FILE" ] && [ -f "$UNIX_ARGS_FILE" ]; then
        log_info "Archivo unix_args.txt detectado. Arrancando JVM..."
        
        # Inyectamos el control de RAM del panel y los argumentos nativos de Forge
        "$JAVA_BIN" -Xms128M -XX:MaxRAMPercentage=95.0 \
             -Dterminal.jline=false \
             -Dterminal.ansi=true \
             @"$UNIX_ARGS_FILE" nogui "$@"
    else
        log_warn "unix_args.txt no encontrado. Intentando arranque fallback vía run.sh..."
        
        if [ -f "run.sh" ]; then
            # Parcheamos el run.sh al vuelo para evitar que anule las variables de Pterodactyl
            sed -i 's/-Xmx[0-9GgMm]*/-XX:MaxRAMPercentage=95.0/g' run.sh
            bash run.sh
        else
            log_error "Fallo de arranque: Estructura ejecutable de Forge Moderno no encontrada."
            exit 1
        fi
    fi
}