#!/bin/bash

###############################################################################
# SCRIPT - Conectar por SSH a instancia EC2
###############################################################################
#
# Este script te ayuda a conectarte por SSH a una instancia EC2
#
# USO:
# =======================
# ./scripts/ec2/connect_ssh.sh [instance-name]
#
# Ejemplos:
#   ./scripts/ec2/connect_ssh.sh shopping-backend
#   ./scripts/ec2/connect_ssh.sh shopping-app
#   ./scripts/ec2/connect_ssh.sh shopping-portal
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_NAME="${1:-shopping-backend}"

echo "🔐 Conectando por SSH a instancia EC2"
echo "======================================"
echo "Buscando instancia: $INSTANCE_NAME"
echo ""

# Buscar la instancia
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${INSTANCE_NAME}" "Name=instance-state-name,Values=running" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "❌ ERROR: No se encontró la instancia '$INSTANCE_NAME' en estado 'running'"
    echo ""
    echo "💡 Instancias disponibles:"
    aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" \
        --region "$AWS_REGION" \
        --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0],InstanceId,PublicIpAddress]' \
        --output table 2>/dev/null || echo "   (No se pudieron listar instancias)"
    exit 1
fi

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
    echo "❌ ERROR: La instancia no tiene IP pública"
    exit 1
fi

echo "✅ Instancia encontrada:"
echo "   Instance ID: $INSTANCE_ID"
echo "   IP Pública: $PUBLIC_IP"
echo ""

# Buscar archivo de clave
KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
if [ ! -f "$KEY_FILE" ]; then
    KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}"
    if [ ! -f "$KEY_FILE" ]; then
        # Buscar en la raíz del proyecto
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        KEY_FILE="$PROJECT_ROOT/${KEY_PAIR_NAME}.pem"
        
        if [ ! -f "$KEY_FILE" ]; then
            echo "❌ ERROR: No se encuentra el archivo de clave"
            echo ""
            echo "💡 Buscando en:"
            echo "   - $HOME/.ssh/${KEY_PAIR_NAME}.pem"
            echo "   - $HOME/.ssh/${KEY_PAIR_NAME}"
            echo "   - $PROJECT_ROOT/${KEY_PAIR_NAME}.pem"
            echo ""
            echo "🔧 Para obtener/configurar la clave:"
            echo "   ./scripts/ec2/setup_ssh_key.sh"
            exit 1
        fi
    fi
fi

# Dar permisos correctos
chmod 400 "$KEY_FILE" 2>/dev/null || true

# Agregar al agente SSH
echo "🔑 Configurando clave SSH..."
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add "$KEY_FILE" 2>/dev/null || true

echo "✅ Clave configurada: $KEY_FILE"
echo ""
echo "🚀 Conectando por SSH..."
echo "   ssh -i $KEY_FILE ec2-user@${PUBLIC_IP}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Conectar
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP}

