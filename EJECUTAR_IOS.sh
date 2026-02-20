#!/bin/bash

# Configurar UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Ir al directorio del proyecto
cd /Users/celiannycastro/Desktop/app-futbol-base/futbol---app

echo "═══════════════════════════════════════════════════════════"
echo "🚀 EJECUTANDO APP EN iOS SIMULATOR"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Mostrar dispositivos disponibles
echo "📱 Dispositivos disponibles:"
flutter devices

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Iniciando compilación para iOS..."
echo "Esto puede tardar 3-8 minutos la primera vez."
echo "═══════════════════════════════════════════════════════════"
echo ""

# Ejecutar Flutter - seleccionará automáticamente el iPhone
flutter run

