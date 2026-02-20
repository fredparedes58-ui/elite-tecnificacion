#!/bin/bash

# Configurar UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Ir al directorio del proyecto
cd /Users/celiannycastro/Desktop/app-futbol-base/futbol---app

echo "═══════════════════════════════════════════════════════════"
echo "🚀 EJECUTANDO APP DE FLUTTER"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Verificando dispositivos disponibles..."
echo ""

# Mostrar dispositivos
flutter devices

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Iniciando compilación..."
echo "Esto puede tardar varios minutos la primera vez."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Ejecutar sin especificar dispositivo - Flutter seleccionará automáticamente
flutter run

