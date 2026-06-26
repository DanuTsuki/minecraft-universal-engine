#!/bin/bash

install_engine() {
    log_info "Iniciando instalación de NeoForge para Minecraft $TARGET_VERSION"

    # Evaluamos si TARGET_VERSION es una versión base (ej. 1.21.1) o un build específico (ej. 21.1.10 o 1.21.1-21.1.10)
    if [[ "$TARGET_VERSION" == *"-"* ]] || [[ ! "$TARGET_VERSION" =~ ^1\. ]]; then
        # Extraemos el build de NeoForge (toma todo lo que esté después del guion, o el string completo si no hay guion)
        NEOFORGE_VERSION="${TARGET_VERSION##*-}"
        log_info "Build específico detectado. Omitiendo Maven. Usando versión: $NEOFORGE_VERSION"
    else
        log_info "Versión base detectada. Resolviendo build más reciente en Maven..."
        # La API de NeoForge usa un formato XML en su Maven. Parseamos para obtener la última versión compatible
        NEOFORGE_VERSION=$(curl -s "https://maven.neoforged.net/releases/net/neoforged/neoforge/maven-metadata.xml" | grep -oP "(?<=<version>)${TARGET_VERSION}\.[0-9]+\.[0-9]+(?=</version>)" | tail -1)

        if [ -z "$NEOFORGE_VERSION" ]; then
            # NeoForge 1.20.5 a 1.20.6 usa un formato ligeramente distinto (ej. 20.6.xx)
            NEOFORGE_VERSION=$(curl -s "https://maven.neoforged.net/releases/net/neoforged/neoforge/maven-metadata.xml" | grep -oP "(?<=<version>)${TARGET_VERSION#1.}\.[0-9]+(?=</version>)" | tail -1)
        fi
    fi

    if [ -z "$NEOFORGE_VERSION" ]; then
        log_error "No se pudo resolver una versión de NeoForge para Minecraft $TARGET_VERSION"
        exit 1
    fi

    log_info "Build de NeoForge seleccionado: $NEOFORGE_VERSION"
    
    INSTALLER_URL="https://maven.neoforged.net/releases/net/neoforged/neoforge/${NEOFORGE_VERSION}/neoforge-${NEOFORGE_VERSION}-installer.jar"
    
    log_info "Descargando instalador de NeoForge..."
    curl -s -S -L -o neoforge-installer.jar "$INSTALLER_URL"

    if [ $? -ne 0 ] || [ ! -f "neoforge-installer.jar" ]; then
        log_error "Fallo crítico en la descarga del instalador de NeoForge."
        exit 1
    fi

    log_info "Ejecutando instalador de dependencias de NeoForge (Server Mode)..."
    # Forzamos la ejecución usando el Java enrutado para evitar conflictos de memoria
    "$JAVA_BIN" -jar neoforge-installer.jar --installServer > install_log.txt 2>&1
    
    if [ ! -d "libraries/net/neoforged/neoforge" ]; then
        log_error "Error: La carpeta de librerías no se generó. Revisa install_log.txt"
        exit 1
    fi

    if [ $? -ne 0 ]; then
        log_error "El instalador de NeoForge devolvió un error durante la extracción."
        exit 1
    fi

    # Limpieza inmediata para optimizar almacenamiento del nodo
    rm -f neoforge-installer.jar neoforge-installer.jar.log
    log_info "Árbol de dependencias de NeoForge instalado con éxito."
}

clean_environment() {
    log_warn "Ejecutando limpieza de entorno restrictiva para NeoForge."
    
    # NeoForge es altamente sensible a conflictos en el Classpath, igual que Forge
    rm -rf libraries mods config user_jvm_args.txt run.sh run.bat
}

start_server() {
    log_info "Iniciando NeoForge mediante mapeo de argumentos modernos."

    # Mapeo dinámico del archivo de argumentos de Unix generado por NeoForge
    UNIX_ARGS_FILE=$(find libraries/net/neoforged/neoforge -name "unix_args.txt" | head -n 1)

    if [ -n "$UNIX_ARGS_FILE" ] && [ -f "$UNIX_ARGS_FILE" ]; then
        log_info "Archivo unix_args.txt detectado. Arrancando JVM..."
        
        # Inyectamos el control de RAM del panel y los argumentos nativos de NeoForge
        "$JAVA_BIN" -Xms128M -XX:MaxRAMPercentage=95.0 \
             -Dterminal.jline=false \
             -Dterminal.ansi=true \
             @user_jvm_args.txt @"$UNIX_ARGS_FILE" nogui "$@"
    else
        log_warn "unix_args.txt no encontrado. Intentando arranque fallback vía run.sh..."
        
        if [ -f "run.sh" ]; then
            # Parcheamos el run.sh al vuelo para evitar que anule las variables de Pterodactyl, 
            # y usamos el JAVA_BIN inyectado
            sed -i 's/-Xmx[0-9GgMm]*/-XX:MaxRAMPercentage=95.0/g' run.sh
            sed -i "s|^java |\"$JAVA_BIN\" |g" run.sh
            bash run.sh
        else
            log_error "Fallo de arranque: Estructura ejecutable de NeoForge no encontrada."
            exit 1
        fi
    fi
}