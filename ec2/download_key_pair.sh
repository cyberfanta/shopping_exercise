#!/bin/bash

###############################################################################
# SCRIPT - Descargar Key Pair desde AWS
###############################################################################
#
# Este script intenta obtener información del key pair desde AWS
# NOTA: AWS no permite descargar claves existentes, solo crear nuevas
# Este script verifica si existe y te ayuda a crearlo si no lo tienes
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
KEY_FILE_ALT="$HOME/.ssh/${KEY_PAIR_NAME}"

echo "🔑 Verificando Key Pair de AWS"
echo "==============================="
echo "Key Pair: $KEY_PAIR_NAME"
echo "Región: $AWS_REGION"
echo ""

# Verificar si el key pair existe en AWS
echo "🔍 Verificando si el key pair existe en AWS..."
KEY_PAIR_EXISTS=$(aws ec2 describe-key-pairs \
    --key-names "$KEY_PAIR_NAME" \
    --region "$AWS_REGION" \
    --query 'KeyPairs[0].KeyPairId' \
    --output text 2>/dev/null)

if [ "$KEY_PAIR_EXISTS" != "None" ] && [ -n "$KEY_PAIR_EXISTS" ]; then
    echo "✅ Key pair existe en AWS: $KEY_PAIR_EXISTS"
    echo ""
    
    # Verificar si el archivo existe localmente
    if [ -f "$KEY_FILE" ]; then
        echo "✅ Archivo de clave encontrado en: $KEY_FILE"
        echo ""
        echo "📋 Información del archivo:"
        ls -lh "$KEY_FILE"
        echo ""
        echo "✅ Todo está listo. Puedes usar los scripts de deployment."
    elif [ -f "$KEY_FILE_ALT" ]; then
        echo "✅ Archivo de clave encontrado en: $KEY_FILE_ALT"
        echo ""
        echo "📋 Información del archivo:"
        ls -lh "$KEY_FILE_ALT"
        echo ""
        echo "✅ Todo está listo. Puedes usar los scripts de deployment."
    else
        echo "⚠️  El key pair existe en AWS pero no tienes el archivo localmente"
        echo ""
        echo "❌ IMPORTANTE: AWS NO permite descargar claves existentes por seguridad"
        echo ""
        echo "📝 Opciones:"
        echo "   1. Si tienes el archivo en otra ubicación, cópialo a:"
        echo "      $KEY_FILE"
        echo "      o"
        echo "      $KEY_FILE_ALT"
        echo ""
        echo "   2. Si perdiste el archivo, necesitas crear un nuevo key pair:"
        echo "      - Ve a AWS Console → EC2 → Key Pairs"
        echo "      - Crea un nuevo key pair con otro nombre"
        echo "      - O elimina el existente y crea uno nuevo"
        echo ""
        echo "   3. Si tienes acceso a otra máquina donde está la clave,"
        echo "      cópiala desde allí"
        exit 1
    fi
else
    echo "❌ El key pair no existe en AWS"
    echo ""
    echo "💡 Para crear un nuevo key pair:"
    echo "   1. Ve a AWS Console → EC2 → Key Pairs"
    echo "   2. Click en 'Create key pair'"
    echo "   3. Nombre: $KEY_PAIR_NAME"
    echo "   4. Tipo: ED25519 (o RSA)"
    echo "   5. Formato: .pem"
    echo "   6. Descarga el archivo y guárdalo en: $KEY_FILE"
    exit 1
fi

echo ""
echo "🔐 Para agregar la clave al agente SSH, ejecuta:"
echo "   ssh-add $KEY_FILE"
echo "   o"
echo "   ssh-add $KEY_FILE_ALT"
echo ""

