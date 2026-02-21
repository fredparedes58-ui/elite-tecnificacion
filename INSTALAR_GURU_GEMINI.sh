#!/bin/bash

# ============================================================
# SCRIPT DE INSTALACIÓN: GURU GEMINI REPORTS
# ============================================================
# Este script te guía en la instalación completa del sistema
# de generación de informes con Google Gemini
# ============================================================

echo "🤖 ============================================================"
echo "   INSTALACIÓN: GURU GEMINI REPORTS"
echo "============================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  NOTA:${NC} Este script te guiará, pero algunos pasos requieren"
echo "   acceso al Dashboard de Supabase."
echo ""
echo "Presiona ENTER para continuar..."
read

echo ""
echo -e "${GREEN}✅ PASO 1: Verificar archivos${NC}"
echo "============================================================"

# Verificar archivos necesarios
FILES=(
  "SETUP_GURU_POSTS.sql"
  "supabase/functions/generate_match_report_gemini/index.ts"
  "GUIA_GEMINI_REPORTS.md"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file existe"
  else
    echo -e "${RED}✗${NC} $file NO encontrado"
    exit 1
  fi
done

echo ""
echo -e "${GREEN}✅ PASO 2: Instalar tabla guru_posts${NC}"
echo "============================================================"
echo ""
echo "1. Abre tu Dashboard de Supabase: https://app.supabase.com"
echo "2. Selecciona tu proyecto"
echo "3. Ve a SQL Editor (menú lateral)"
echo "4. Click en 'New query'"
echo "5. Abre el archivo: SETUP_GURU_POSTS.sql"
echo "6. Copia TODO el contenido"
echo "7. Pégalo en el editor SQL"
echo "8. Click en 'Run' (botón verde)"
echo ""
echo "Presiona ENTER cuando hayas ejecutado el SQL..."
read

echo ""
echo -e "${GREEN}✅ PASO 3: Configurar secreto GEMINI_API_KEY${NC}"
echo "============================================================"
echo ""
echo "1. En el Dashboard de Supabase, ve a:"
echo "   Settings → Edge Functions → Secrets"
echo ""
echo "2. Click en 'Add new secret'"
echo ""
echo "3. Agrega:"
echo "   Name: GEMINI_API_KEY"
echo "   Value: Tu API Key de Google Gemini"
echo ""
echo "   Para obtener tu API Key:"
echo "   https://makersuite.google.com/app/apikey"
echo ""
echo "4. Click en 'Save'"
echo ""
echo "Presiona ENTER cuando hayas configurado el secreto..."
read

echo ""
echo -e "${GREEN}✅ PASO 4: Desplegar Edge Function${NC}"
echo "============================================================"
echo ""
echo "Opción A: Usando Dashboard (Recomendado si no tienes CLI)"
echo "-----------------------------------------------------------"
echo "1. Ve a: Dashboard → Edge Functions"
echo "2. Click en 'Create a new function'"
echo "3. Nombre: generate_match_report_gemini"
echo "4. Abre el archivo: supabase/functions/generate_match_report_gemini/index.ts"
echo "5. Copia TODO el contenido"
echo "6. Pégalo en el editor de la función"
echo "7. Click en 'Deploy'"
echo ""
echo "Opción B: Usando Supabase CLI (si lo tienes instalado)"
echo "-----------------------------------------------------------"
echo "Comando: supabase functions deploy generate_match_report_gemini"
echo ""
echo "Presiona ENTER cuando hayas desplegado la función..."
read

echo ""
echo -e "${GREEN}✅ INSTALACIÓN COMPLETA${NC}"
echo "============================================================"
echo ""
echo "🎉 ¡El botón GURU GURU está listo para usar!"
echo ""
echo "Para probarlo:"
echo "1. Abre la app Flutter"
echo "2. Ve a Partidos → Selecciona un partido finalizado"
echo "3. Click en 'REGISTRAR ESTADÍSTICAS'"
echo "4. Verás el botón 'GURU GURU' debajo de 'GUARDAR ESTADÍSTICAS'"
echo "5. Click en 'GURU GURU' para generar los informes"
echo ""
echo "Para más detalles, consulta: GUIA_GEMINI_REPORTS.md"
echo ""
