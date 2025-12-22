#!/bin/bash

###############################################################################
# SCRIPT - Configurar SSH Key para EC2
###############################################################################
#
# Este script ayuda a configurar la clave SSH para los deployments
# Si no tienes la clave, te ayuda a crearla o descargarla
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
KEY_FILE_PROJECT="$PROJECT_ROOT/${KEY_PAIR_NAME}.pem"
KEY_FILE_HOME="$HOME/.ssh/${KEY_PAIR_NAME}.pem"

echo "🔑 Configurando SSH Key para EC2"
echo "=================================="
echo ""

# Verificar si la clave ya existe en el proyecto
if [ -f "$KEY_FILE_PROJECT" ]; then
    echo "✅ Clave encontrada en el proyecto: $KEY_FILE_PROJECT"
    chmod 400 "$KEY_FILE_PROJECT"
    echo "✅ Permisos configurados"
    exit 0
fi

# Verificar si existe en ~/.ssh
if [ -f "$KEY_FILE_HOME" ]; then
    echo "✅ Clave encontrada en: $KEY_FILE_HOME"
    echo "  → Copiando al proyecto..."
    cp "$KEY_FILE_HOME" "$KEY_FILE_PROJECT"
    chmod 400 "$KEY_FILE_PROJECT"
    echo "✅ Clave copiada a: $KEY_FILE_PROJECT"
    exit 0
fi

# Verificar si el key pair existe en AWS
echo "🔍 Verificando key pair en AWS..."
KEY_EXISTS=$(aws ec2 describe-key-pairs \
    --key-names "$KEY_PAIR_NAME" \
    --region "$AWS_REGION" \
    --query 'KeyPairs[0].KeyPairId' \
    --output text 2>/dev/null)

if [ "$KEY_EXISTS" != "None" ] && [ -n "$KEY_EXISTS" ]; then
    echo "⚠️  El key pair existe en AWS pero no tienes el archivo localmente"
    echo ""
    echo "❌ IMPORTANTE: AWS NO permite descargar claves existentes por seguridad"
    echo ""
    echo "📝 Opciones:"
    echo "   1. Si tienes el archivo en otra ubicación, cópialo a:"
    echo "      $KEY_FILE_PROJECT"
    echo ""
    echo "   2. Si perdiste el archivo completamente:"
    echo "      - Necesitas crear un nuevo key pair"
    echo "      - O eliminar el existente y crear uno nuevo"
    echo ""
    read -p "¿Deseas crear un nuevo key pair? (esto eliminará el existente) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🗑️  Eliminando key pair existente..."
        aws ec2 delete-key-pair \
            --key-name "$KEY_PAIR_NAME" \
            --region "$AWS_REGION" >/dev/null 2>&1
        
        echo "✅ Key pair eliminado"
        echo ""
    else
        echo "Operación cancelada. Necesitas el archivo de clave para continuar."
        exit 1
    fi
fi

# Crear nuevo key pair
echo "🔨 Creando nuevo key pair..."
KEY_MATERIAL=$(aws ec2 create-key-pair \
    --key-name "$KEY_PAIR_NAME" \
    --key-type ed25519 \
    --region "$AWS_REGION" \
    --query 'KeyMaterial' \
    --output text 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$KEY_MATERIAL" ]; then
    # Guardar en el proyecto
    echo "$KEY_MATERIAL" > "$KEY_FILE_PROJECT"
    chmod 400 "$KEY_FILE_PROJECT"
    
    # También copiar a ~/.ssh
    mkdir -p "$HOME/.ssh"
    cp "$KEY_FILE_PROJECT" "$KEY_FILE_HOME"
    chmod 400 "$KEY_FILE_HOME"
    
    echo "✅ Key pair creado y guardado en:"
    echo "   - $KEY_FILE_PROJECT"
    echo "   - $KEY_FILE_HOME"
    echo ""
    echo "✅ Configuración completada"
else
    echo "❌ ERROR: No se pudo crear el key pair"
    exit 1
fi

