#!/bin/bash

determine_required_java() {
    REQUIRED_JAVA_VERSION="21"  # Default para versiones modernas

    if [ "$MC_MINOR" -le 16 ]; then
        REQUIRED_JAVA_VERSION="8"
    fi

    # Minecraft 1.17 originalmente usaba Java 16, pero Java 17 es la versión LTS estable recomendada
    if [ "$MC_MINOR" -eq 17 ]; then
        REQUIRED_JAVA_VERSION="17"
    fi

    if [ "$MC_MINOR" -ge 18 ] && [ "$MC_MINOR" -le 20 ]; then
        REQUIRED_JAVA_VERSION="17"
    fi

    if [ "$MC_MINOR" -ge 21 ]; then
        REQUIRED_JAVA_VERSION="21"
    fi

    # Excepción estricta para Forge Antiguo (1.12.2, etc.)
    if [ "$ENGINE_PROFILE" = "forge_legacy" ]; then
        REQUIRED_JAVA_VERSION="8"
    fi

    log_info "Java requerido para esta versión: Java $REQUIRED_JAVA_VERSION"
}

set_java_executable() {
    # Asignamos la ruta exacta del binario de Java dentro de nuestra imagen Alpine
    if [ "$REQUIRED_JAVA_VERSION" = "8" ]; then
        export JAVA_BIN="/usr/lib/jvm/java-1.8-openjdk/bin/java"
    elif [ "$REQUIRED_JAVA_VERSION" = "17" ]; then
        export JAVA_BIN="/usr/lib/jvm/java-17-openjdk/bin/java"
    elif [ "$REQUIRED_JAVA_VERSION" = "21" ]; then
        export JAVA_BIN="/usr/lib/jvm/java-21-openjdk/bin/java"
    else
        export JAVA_BIN="java" # Fallback al comando del sistema por defecto
    fi

    # Verificamos que el ejecutable realmente exista en el contenedor
    if [ -f "$JAVA_BIN" ]; then
        log_info "Enrutamiento de Java exitoso: Usando Java $REQUIRED_JAVA_VERSION"
    else
        log_warn "No se encontró el binario específico ($JAVA_BIN). Usando Java por defecto del sistema."
        export JAVA_BIN="java"
    fi
}

initialize_java_system() {
    determine_required_java
    set_java_executable
    
    log_info "Versión de Java inyectada para el arranque:"
    "$JAVA_BIN" -version 2>&1 | head -n 1
}