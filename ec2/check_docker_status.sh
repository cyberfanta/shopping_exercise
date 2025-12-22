#!/bin/bash

###############################################################################
# SCRIPT - Verificar estado de Docker en instancia EC2
###############################################################################
#
# Este script verifica el estado de Docker y los contenedores en una instancia
#
# USO:
# =======================
# ./scripts/ec2/check_docker_status.sh [instance-name]
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_NAME="${1:-shopping-backend}"

echo "🔍 Verificando estado de Docker en EC2"
echo "======================================="
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

# Verificar estado
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << 'ENDSSH'
    echo "🔍 Estado de Docker:"
    sudo systemctl status docker --no-pager -l | head -5
    echo ""
    
    echo "📦 Contenedores Docker:"
    sudo docker ps -a
    echo ""
    
    echo "📊 Uso de recursos:"
    sudo docker stats --no-stream || echo "  (No hay contenedores corriendo)"
    echo ""
    
    echo "📝 Logs recientes del API (últimas 30 líneas):"
    sudo docker logs shopping_api --tail 30 2>&1 || echo "  (Contenedor shopping_api no encontrado)"
    echo ""
    
    echo "🔗 Verificando conectividad del API:"
    curl -s http://localhost:3000/health || echo "  ❌ El API no responde en localhost:3000"
    echo ""
    
    echo "📁 Verificando docker-compose.yml:"
    if [ -f "/home/ec2-user/shopping_exercise/shopping_exercise_backend/docker-compose.yml" ]; then
        echo "  ✅ docker-compose.yml encontrado"
        cd /home/ec2-user/shopping_exercise/shopping_exercise_backend
        echo "  → Estado de docker-compose:"
        sudo docker-compose ps
    else
        echo "  ❌ docker-compose.yml no encontrado"
    fi
ENDSSH

echo ""
echo "✅ Verificación completada"

