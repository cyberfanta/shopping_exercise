#!/bin/bash

###############################################################################
# SCRIPT MAESTRO DE DEPLOYMENT - Del Stack
###############################################################################
#
# Este script despliega el stack en orden:
# 1. Backend (API + PostgreSQL + Adminer)
# 2. App Flutter
# 3. Portal Flutter
# 4. Landing Page
#
###############################################################################

set -e

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

print_step() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ============================================================================
# VALIDACIÓN DE PREREQUISITOS
# ============================================================================

print_step "🔍 VALIDANDO PREREQUISITOS"

# Verificar que los scripts existan
REQUIRED_SCRIPTS=(
    "deploy_backend_ec2.sh"
    "deploy_app_flutter_ec2.sh"
    "deploy_portal_flutter_ec2.sh"
    "deploy_landing_ec2.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        print_error "Script requerido no encontrado: $script"
        exit 1
    fi
    if [ ! -x "$SCRIPT_DIR/$script" ]; then
        print_warning "Dando permisos de ejecución a $script"
        chmod +x "$SCRIPT_DIR/$script"
    fi
done

print_success "Todos los scripts están disponibles"

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI no está instalado"
    echo "  💡 Instala AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

print_success "AWS CLI está instalado"

# Verificar que estemos en el directorio correcto
if [ ! -d "$PROJECT_ROOT/shopping_exercise_backend" ]; then
    print_error "No se encontró el directorio shopping_exercise_backend"
    echo "  💡 Asegúrate de ejecutar este script desde la raíz del proyecto"
    exit 1
fi

print_success "Estructura del proyecto verificada"
echo ""

# ============================================================================
# MENÚ DE OPCIONES
# ============================================================================

print_step "📋 OPCIONES DE DEPLOYMENT"

echo "Selecciona qué deseas desplegar:"
echo ""
echo "  1) Todo el stack (Backend → App → Portal → Landing)"
echo "  2) Solo Backend"
echo "  3) Solo App Flutter"
echo "  4) Solo Portal Flutter"
echo "  5) Solo Landing Page"
echo "  6) Backend + App + Portal (sin Landing)"
echo "  7) Solo Frontend (App + Portal + Landing)"
echo ""
read -p "Opción [1-7]: " OPTION

case $OPTION in
    1)
        DEPLOY_BACKEND=true
        DEPLOY_APP=true
        DEPLOY_PORTAL=true
        DEPLOY_LANDING=true
        ;;
    2)
        DEPLOY_BACKEND=true
        DEPLOY_APP=false
        DEPLOY_PORTAL=false
        DEPLOY_LANDING=false
        ;;
    3)
        DEPLOY_BACKEND=false
        DEPLOY_APP=true
        DEPLOY_PORTAL=false
        DEPLOY_LANDING=false
        ;;
    4)
        DEPLOY_BACKEND=false
        DEPLOY_APP=false
        DEPLOY_PORTAL=true
        DEPLOY_LANDING=false
        ;;
    5)
        DEPLOY_BACKEND=false
        DEPLOY_APP=false
        DEPLOY_PORTAL=false
        DEPLOY_LANDING=true
        ;;
    6)
        DEPLOY_BACKEND=true
        DEPLOY_APP=true
        DEPLOY_PORTAL=true
        DEPLOY_LANDING=false
        ;;
    7)
        DEPLOY_BACKEND=false
        DEPLOY_APP=true
        DEPLOY_PORTAL=true
        DEPLOY_LANDING=true
        ;;
    *)
        print_error "Opción inválida"
        exit 1
        ;;
esac

echo ""
print_success "Opción seleccionada: $OPTION"
echo ""

# ============================================================================
# DEPLOYMENT PASO A PASO
# ============================================================================

START_TIME=$(date +%s)

# PASO 1: Backend
if [ "$DEPLOY_BACKEND" = true ]; then
    print_step "🚀 PASO 1: DEPLOYMENT DEL BACKEND"
    echo "Esto puede tardar varios minutos..."
    echo ""
    
    cd "$PROJECT_ROOT"
    if "$SCRIPT_DIR/deploy_backend_ec2.sh"; then
        print_success "Backend desplegado correctamente"
        
        # Obtener IP pública para mostrar
        INSTANCE_ID=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=shopping-app" "Name=instance-state-name,Values=running" \
            --query 'Reservations[0].Instances[0].InstanceId' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
            PUBLIC_IP=$(aws ec2 describe-instances \
                --instance-ids "$INSTANCE_ID" \
                --query 'Reservations[0].Instances[0].PublicIpAddress' \
                --output text 2>/dev/null || echo "")
            
            if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
                echo ""
                echo "  🌐 Backend API: http://$PUBLIC_IP/api"
                echo "  🌐 Health Check: http://$PUBLIC_IP/health"
                echo "  🌐 Adminer: http://$PUBLIC_IP/adminer"
            fi
        fi
    else
        print_error "Falló el deployment del backend"
        exit 1
    fi
    
    echo ""
    read -p "Presiona Enter para continuar con el siguiente paso..."
    echo ""
fi

# PASO 2: App Flutter
if [ "$DEPLOY_APP" = true ]; then
    print_step "📱 PASO 2: DEPLOYMENT DE LA APP FLUTTER"
    echo "Esto compilará Flutter localmente y luego desplegará..."
    echo ""
    
    cd "$PROJECT_ROOT"
    if "$SCRIPT_DIR/deploy_app_flutter_ec2.sh"; then
        print_success "App Flutter desplegada correctamente"
    else
        print_error "Falló el deployment de la app Flutter"
        exit 1
    fi
    
    echo ""
    read -p "Presiona Enter para continuar con el siguiente paso..."
    echo ""
fi

# PASO 3: Portal Flutter
if [ "$DEPLOY_PORTAL" = true ]; then
    print_step "⚙️  PASO 3: DEPLOYMENT DEL PORTAL FLUTTER"
    echo "Esto compilará Flutter localmente y luego desplegará..."
    echo ""
    
    cd "$PROJECT_ROOT"
    if "$SCRIPT_DIR/deploy_portal_flutter_ec2.sh"; then
        print_success "Portal Flutter desplegado correctamente"
    else
        print_error "Falló el deployment del portal Flutter"
        exit 1
    fi
    
    echo ""
    read -p "Presiona Enter para continuar con el siguiente paso..."
    echo ""
fi

# PASO 4: Landing Page
if [ "$DEPLOY_LANDING" = true ]; then
    print_step "🌐 PASO 4: DEPLOYMENT DEL LANDING PAGE"
    echo "Esto compilará React localmente y luego desplegará..."
    echo ""
    
    cd "$PROJECT_ROOT"
    if "$SCRIPT_DIR/deploy_landing_ec2.sh"; then
        print_success "Landing page desplegada correctamente"
    else
        print_error "Falló el deployment del landing page"
        exit 1
    fi
fi

# ============================================================================
# RESUMEN FINAL
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

print_step "✅ DEPLOYMENT COMPLETADO"

# Obtener IP pública final
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=shopping-app" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "")

if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "None" ]; then
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "None" ]; then
        echo ""
        echo "🌐 🌐 🌐 TU APLICACIÓN ESTÁ DISPONIBLE EN: 🌐 🌐 🌐"
        echo ""
        [ "$DEPLOY_LANDING" = true ] && echo "   👉 Landing: http://$PUBLIC_IP/ 👈"
        [ "$DEPLOY_APP" = true ] && echo "   👉 App: http://$PUBLIC_IP/app 👈"
        [ "$DEPLOY_PORTAL" = true ] && echo "   👉 Portal: http://$PUBLIC_IP/portal 👈"
        [ "$DEPLOY_BACKEND" = true ] && echo "   👉 API: http://$PUBLIC_IP/api 👈"
        [ "$DEPLOY_BACKEND" = true ] && echo "   👉 Adminer: http://$PUBLIC_IP/adminer 👈"
        echo ""
    fi
fi

echo "⏱️  Tiempo total: ${MINUTES}m ${SECONDS}s"
echo ""
echo "=========================================="
echo ""

