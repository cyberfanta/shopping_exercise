#!/bin/bash

###############################################################################
# SCRIPT - Instalar Docker Buildx en instancia EC2
###############################################################################
#
# Este script instala Docker Buildx que es requerido para docker compose build
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_NAME="${1:-shopping-backend}"

echo "🔧 Instalando Docker Buildx en EC2"
echo "==================================="
echo "Instancia: $INSTANCE_NAME"
echo ""

# Buscar instancia
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "❌ ERROR: Instancia no encontrada o no está corriendo"
    exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

# Buscar clave
KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
if [ ! -f "$KEY_FILE" ]; then
    KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}"
    if [ ! -f "$KEY_FILE" ]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        KEY_FILE="$PROJECT_ROOT/${KEY_PAIR_NAME}.pem"
    fi
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ ERROR: No se encuentra el archivo de clave"
    exit 1
fi

chmod 400 "$KEY_FILE" 2>/dev/null || true

echo "📍 IP Pública: $PUBLIC_IP"
echo ""

# Instalar Buildx
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << 'ENDSSH'
    echo "🔧 Instalando Docker Buildx..."
    
    # Verificar si ya está instalado
    if docker buildx version &> /dev/null 2>&1; then
        echo "  ✅ Docker Buildx ya está instalado"
        docker buildx version
        exit 0
    fi
    
    # Obtener última versión
    echo "  → Obteniendo última versión de Buildx..."
    BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$BUILDX_VERSION" ]; then
        BUILDX_VERSION="v0.12.1"  # Fallback
        echo "  ⚠️  No se pudo obtener versión, usando: $BUILDX_VERSION"
    else
        echo "  → Versión encontrada: $BUILDX_VERSION"
    fi
    
    # Crear directorio de plugins
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    
    # Descargar Buildx
    echo "  → Descargando Buildx..."
    sudo curl -SL "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-buildx
    
    # Dar permisos
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx
    
    # Verificar instalación
    if docker buildx version &> /dev/null 2>&1; then
        echo "  ✅ Docker Buildx instalado correctamente"
        docker buildx version
    else
        echo "  ⚠️  Buildx instalado pero puede requerir reinicio de sesión"
        echo "  💡 Prueba: docker buildx version"
    fi
    
    # Crear y usar builder
    echo ""
    echo "  → Configurando builder..."
    docker buildx create --name builder --use 2>/dev/null || docker buildx use builder 2>/dev/null || true
    docker buildx inspect --bootstrap 2>/dev/null || true
    
    echo ""
    echo "  ✅ Docker Buildx configurado"
    echo "  📋 Builders disponibles:"
    docker buildx ls
ENDSSH

echo ""
echo "✅ Proceso completado"

