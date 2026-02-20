#!/bin/bash

# Script para instalar CocoaPods y configurar el proyecto iOS
# Ejecuta este script DESPUÉS de instalar Homebrew

echo "═══════════════════════════════════════════════════════════"
echo "📦 INSTALANDO COCOAPODS Y CONFIGURANDO PROYECTO"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Verificar si Homebrew está instalado
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew no está instalado."
    echo "   Primero ejecuta:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "✅ Homebrew encontrado"
echo ""

# Instalar CocoaPods
echo "📦 Instalando CocoaPods..."
brew install cocoapods

if [ $? -eq 0 ]; then
    echo "✅ CocoaPods instalado correctamente"
    echo ""
    
    # Verificar versión
    echo "📋 Versión de CocoaPods:"
    pod --version
    echo ""
    
    # Configurar UTF-8 para CocoaPods
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    # Ir al directorio ios
    echo "📂 Configurando proyecto iOS..."
    cd ios
    
    # Instalar pods
    echo "📦 Instalando pods del proyecto..."
    pod install
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ ¡Todo listo!"
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "🚀 PRÓXIMOS PASOS:"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        echo "1. Abrir simulador:"
        echo "   open -a Simulator"
        echo ""
        echo "2. Ejecutar la app en iOS:"
        echo "   cd .."
        echo "   flutter run -d ios"
        echo ""
        echo "O ejecutar en macOS:"
        echo "   flutter run -d macos"
        echo ""
    else
        echo "❌ Error al instalar pods"
        exit 1
    fi
else
    echo "❌ Error al instalar CocoaPods"
    exit 1
fi
