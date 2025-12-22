#!/bin/bash

###############################################################################
# SCRIPT - Arreglar Docker Compose en instancia EC2
###############################################################################
#
# Este script arregla la instalación de Docker Compose si está rota
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_NAME="${1:-shopping-backend}"

echo "🔧 Arreglando Docker Compose en EC2"
echo "===================================="
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

# Arreglar Docker Compose
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << 'ENDSSH'
    echo "🔧 Arreglando Docker Compose..."
    
    # Eliminar instalaciones rotas
    sudo rm -f /usr/local/bin/docker-compose
    sudo rm -f /usr/local/lib/docker/cli-plugins/docker-compose
    
    # Crear directorio si no existe
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    
    # Instalar Docker Compose V2 (plugin)
    echo "  → Descargando Docker Compose..."
    sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose
    
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    
    # Crear symlink para compatibilidad
    sudo ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    # Verificar instalación
    echo ""
    echo "  → Verificando instalación..."
    if docker compose version &> /dev/null; then
        echo "  ✅ Docker Compose instalado correctamente (plugin)"
        docker compose version
    elif docker-compose version &> /dev/null; then
        echo "  ✅ Docker Compose instalado correctamente (symlink)"
        docker-compose version
    else
        echo "  ⚠️  Docker Compose instalado pero puede requerir reinicio de sesión"
        echo "  💡 Prueba: docker compose version"
    fi
ENDSSH

echo ""
echo "✅ Proceso completado"

