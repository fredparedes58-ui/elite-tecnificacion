#!/bin/bash

# Configurar UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Cambiar al directorio del proyecto
cd "$(dirname "$0")"

echo "═══════════════════════════════════════════════════════════"
echo "🚀 EJECUTANDO LA APP EN iOS"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Compilando y ejecutando la app..."
echo "Esto puede tardar varios minutos la primera vez."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Ejecutar Flutter usando el ID del simulador o seleccionar automáticamente
echo "Buscando dispositivos disponibles..."
flutter devices

echo ""
echo "Ejecutando la app..."
echo "Si tienes múltiples dispositivos, presiona el número del dispositivo iOS"
echo ""

# Intentar ejecutar en iOS (automático si solo hay uno)
flutter run -d ios 2>&1 || flutter run 2>&1

