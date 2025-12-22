#!/bin/bash

###############################################################################
# SCRIPT - Obtener información del Key Pair y crear script de descarga
###############################################################################
#
# Este script verifica el key pair en AWS y te ayuda a descargarlo
# NOTA: AWS NO permite descargar claves existentes por seguridad
# Este script te ayuda a verificar y te da instrucciones
#
###############################################################################

KEY_PAIR_NAME="aws-eb-shopping-exercise"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "🔑 Verificando Key Pair en AWS"
echo "==============================="
echo ""

# Verificar si el key pair existe
KEY_INFO=$(aws ec2 describe-key-pairs \
    --key-names "$KEY_PAIR_NAME" \
    --region "$AWS_REGION" \
    --output json 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$KEY_INFO" ]; then
    echo "✅ Key pair encontrado en AWS:"
    echo "$KEY_INFO" | jq -r '.KeyPairs[0] | "   Nombre: \(.KeyName)\n   ID: \(.KeyPairId)\n   Tipo: \(.KeyType)\n   Huella: \(.KeyFingerprint)"'
    echo ""
    echo "⚠️  IMPORTANTE: AWS NO permite descargar claves existentes"
    echo ""
    echo "📝 Opciones:"
    echo ""
    echo "1. Si ya tienes el archivo de clave:"
    echo "   - Cópialo a la raíz del proyecto como: ${KEY_PAIR_NAME}.pem"
    echo "   - O guárdalo en: ~/.ssh/${KEY_PAIR_NAME}.pem"
    echo ""
    echo "2. Si perdiste el archivo:"
    echo "   - Necesitas crear un nuevo key pair en AWS"
    echo "   - O usar el existente si lo tienes en otra máquina"
    echo ""
    echo "3. Para crear un nuevo key pair (si perdiste el archivo):"
    echo "   aws ec2 create-key-pair \\"
    echo "     --key-name ${KEY_PAIR_NAME}-new \\"
    echo "     --key-type ed25519 \\"
    echo "     --query 'KeyMaterial' \\"
    echo "     --output text > ${KEY_PAIR_NAME}-new.pem"
    echo "   chmod 400 ${KEY_PAIR_NAME}-new.pem"
    echo ""
else
    echo "❌ Key pair no encontrado en AWS"
    echo ""
    echo "💡 Para crear un nuevo key pair:"
    echo "   aws ec2 create-key-pair \\"
    echo "     --key-name ${KEY_PAIR_NAME} \\"
    echo "     --key-type ed25519 \\"
    echo "     --query 'KeyMaterial' \\"
    echo "     --output text > ${KEY_PAIR_NAME}.pem"
    echo "   chmod 400 ${KEY_PAIR_NAME}.pem"
    echo ""
    echo "   Esto creará el archivo ${KEY_PAIR_NAME}.pem en el directorio actual"
fi

