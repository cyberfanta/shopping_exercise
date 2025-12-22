#!/bin/bash

###############################################################################
# SCRIPT DE DEPLOYMENT - PORTAL FLUTTER A EC2 CON NGINX
###############################################################################
#
# Este script:
# 1. Busca la instancia EC2 "shopping-app" (compartida con backend y app)
# 2. Se conecta por SSH
# 3. Actualiza el código desde GitHub
# 4. Compila Flutter Web en modo release
# 5. Configura nginx para servir el portal en /portal
#
# CONFIGURACIÓN REQUERIDA:
# =======================
# 1. AWS_REGION: Región de AWS (ej: us-east-1)
# 2. KEY_PAIR_NAME: Nombre del key pair de AWS
# 3. GITHUB_REPO_URL: URL del repositorio GitHub
# 4. GITHUB_TOKEN (opcional): Token de acceso
# 5. EC2_INSTANCE_NAME: Debe ser "shopping-app" (compartida con backend y app)
#
###############################################################################

set -e

# ============================================================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================================================

AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_PAIR_NAME="aws-eb-shopping-exercise"  # ⚠️ REQUERIDO: Nombre de tu key pair de AWS
EC2_INSTANCE_NAME="shopping-app"  # Nombre para la instancia (compartida con backend y app)
GITHUB_REPO_URL="git@github.com:cyberfanta/shopping_exercise.git"  # ⚠️ REQUERIDO: URL del repo
GITHUB_TOKEN=""            # Opcional: Token para repos privados
INSTANCE_TYPE="t3.micro"   # Tipo de instancia
ALLOWED_SSH_IP="38.74.224.33/32"  # IP permitida para SSH

# ============================================================================
# VALIDACIÓN
# ============================================================================

if [ -z "$KEY_PAIR_NAME" ]; then
    echo "❌ ERROR: KEY_PAIR_NAME no está configurado"
    exit 1
fi

if [ -z "$GITHUB_REPO_URL" ]; then
    echo "❌ ERROR: GITHUB_REPO_URL no está configurado"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ ERROR: AWS CLI no está instalado"
    exit 1
fi

# ============================================================================
# FUNCIONES
# ============================================================================

run_remote_command() {
    local command="$1"
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} "$command" | tee -a "$HISTORY_FILE"
}

# ============================================================================
# INICIO DEL DEPLOYMENT
# ============================================================================

echo "🚀 Iniciando deployment del Portal Flutter a EC2"
echo "=================================================="
echo "Región: $AWS_REGION"
echo "Instance Name: $EC2_INSTANCE_NAME"
echo "Key Pair: $KEY_PAIR_NAME"
echo ""

# ============================================================================
# PASO 1: Buscar instancia EC2
# ============================================================================

echo "🔍 Paso 1: Buscando instancia EC2..."

# Buscar instancia existente
INSTANCE_ID=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=${EC2_INSTANCE_NAME}" "Name=instance-state-name,Values=running,stopped,stopping" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
    echo "  ⚠️  No se encontró instancia existente con nombre: $EC2_INSTANCE_NAME"
    echo "  💡 Ejecuta primero el script deploy_backend_ec2.sh para crear la instancia"
    exit 1
fi

echo "  ✅ Instancia encontrada: $INSTANCE_ID"

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "  ❌ ERROR: No se pudo obtener la IP pública"
    exit 1
fi

echo "  ✅ IP Pública: $PUBLIC_IP"

# Iniciar instancia si está detenida
INSTANCE_STATE=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].State.Name" \
    --output text)

if [ "$INSTANCE_STATE" = "stopped" ] || [ "$INSTANCE_STATE" = "stopping" ]; then
    echo "  → Iniciando instancia..."
    aws ec2 start-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" > /dev/null
    echo "  ⏳ Esperando a que la instancia esté corriendo..."
    aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"
    
    # Actualizar IP pública
    sleep 5
    PUBLIC_IP=$(aws ec2 describe-instances \
        --region "$AWS_REGION" \
        --instance-ids "$INSTANCE_ID" \
        --query "Reservations[0].Instances[0].PublicIpAddress" \
        --output text)
    echo "  ✅ Instancia iniciada. Nueva IP: $PUBLIC_IP"
fi

echo ""

# ============================================================================
# PASO 2: Configurar SSH
# ============================================================================

echo "🔐 Paso 2: Configurando SSH..."

# Buscar archivo de clave
KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
if [ ! -f "$KEY_FILE" ]; then
    KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}"
fi

if [ ! -f "$KEY_FILE" ]; then
    echo "  ❌ ERROR: No se encuentra el archivo de clave en:"
    echo "     $HOME/.ssh/${KEY_PAIR_NAME}.pem"
    echo "     $HOME/.ssh/${KEY_PAIR_NAME}"
    exit 1
fi

# Configurar permisos
chmod 400 "$KEY_FILE" 2>/dev/null || true

# Agregar clave al agente SSH
echo "  → Agregando clave al agente SSH..."
eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add "$KEY_FILE" 2>/dev/null || true

echo "  ✅ SSH configurado"
echo ""

# ============================================================================
# PASO 3: Esperar SSH y verificar conexión
# ============================================================================

echo "⏳ Paso 3: Esperando SSH..."

max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
       -i "$KEY_FILE" ec2-user@${PUBLIC_IP} "echo 'SSH ready'" 2>/dev/null; then
        echo "  ✅ SSH disponible"
        break
    fi
    attempt=$((attempt + 1))
    sleep 5
done

if [ $attempt -eq $max_attempts ]; then
    echo "  ❌ Timeout esperando SSH"
    exit 1
fi

echo ""

# ============================================================================
# PASO 4: Configurar historial de comandos
# ============================================================================

HISTORY_FILE="/tmp/ec2_deployment_history_$(date +%Y%m%d_%H%M%S).log"
echo "📝 Historial de comandos: $HISTORY_FILE"
echo ""

# ============================================================================
# PASO 5: Actualizar código desde GitHub
# ============================================================================

echo "📥 Paso 5: Actualizando código desde GitHub..."

REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    GITHUB_REPO_URL="$GITHUB_REPO_URL"
    GITHUB_TOKEN="$GITHUB_TOKEN"
    
    echo "  → Navegando a directorio home..."
    cd /home/ec2-user
    
    if [ -d "\$REPO_NAME" ]; then
        echo "  → Repositorio existe, actualizando..."
        cd "\$REPO_NAME"
        
        # Actualizar desde git
        echo "  → Obteniendo cambios desde git..."
        git fetch origin 2>&1 || true
        git reset --hard origin/main 2>&1 || git reset --hard origin/master 2>&1 || true
        git clean -fd 2>&1 || true
        
        # Intentar pull
        git pull origin main 2>&1 || git pull origin master 2>&1 || true
    else
        echo "  → Repositorio no existe, clonando..."
        # Convertir SSH a HTTPS si no hay token
        if [ -z "\$GITHUB_TOKEN" ]; then
            REPO_URL=\$(echo "\$GITHUB_REPO_URL" | sed 's|git@github.com:|https://github.com/|' | sed 's|\.git$||')
            git clone "\$REPO_URL.git" "\$REPO_NAME" 2>&1
        else
            git clone "\$GITHUB_REPO_URL" "\$REPO_NAME" 2>&1
        fi
        cd "\$REPO_NAME"
    fi
    
    echo "  ✅ Repositorio actualizado"
    echo "  📁 Ubicación: /home/ec2-user/\$REPO_NAME"
ENDSSH

echo "  ✅ Código actualizado"
echo ""

# ============================================================================
# PASO 6: Verificar Flutter (ya debería estar instalado)
# ============================================================================

echo "📦 Paso 6: Verificando Flutter..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    export PATH="\$PATH:/home/ec2-user/flutter/bin"
    
    if ! command -v flutter &> /dev/null; then
        echo "  ❌ ERROR: Flutter no está instalado"
        echo "  💡 Ejecuta primero el script deploy_app_flutter_ec2.sh"
        exit 1
    fi
    
    echo "  → Verificando versión de Flutter..."
    CURRENT_VERSION=\$(flutter --version | head -1 | awk '{print \$2}' 2>/dev/null || echo "unknown")
    echo "  📌 Versión actual: \$CURRENT_VERSION"
    
    # Verificar versión de Dart
    DART_VERSION=\$(flutter --version | grep -i "dart" | awk '{print \$2}' 2>/dev/null || echo "unknown")
    echo "  📌 Versión de Dart: \$DART_VERSION"
    
    # Verificar si necesita actualización (Dart debe ser >= 3.10.4)
    NEEDS_UPDATE=false
    if [ "\$DART_VERSION" != "unknown" ]; then
        # Comparar versiones de Dart (formato: 3.10.4)
        DART_MAJOR=\$(echo \$DART_VERSION | cut -d. -f1)
        DART_MINOR=\$(echo \$DART_VERSION | cut -d. -f2)
        DART_PATCH=\$(echo \$DART_VERSION | cut -d. -f3)
        
        if [ "\$DART_MAJOR" -lt 3 ] || ([ "\$DART_MAJOR" -eq 3 ] && [ "\$DART_MINOR" -lt 10 ]) || ([ "\$DART_MAJOR" -eq 3 ] && [ "\$DART_MINOR" -eq 10 ] && [ "\$DART_PATCH" -lt 4 ]); then
            NEEDS_UPDATE=true
        fi
    else
        NEEDS_UPDATE=true
    fi
    
    if [ "\$NEEDS_UPDATE" = true ]; then
        echo "  → Actualizando Flutter a la última versión estable..."
        cd /home/ec2-user/flutter
        git fetch origin stable 2>&1 || true
        git reset --hard origin/stable 2>&1 || true
        git pull origin stable 2>&1 || true
        flutter upgrade --force 2>&1 || {
            echo "  ⚠️  flutter upgrade falló, intentando reinstalar..."
            cd /home/ec2-user
            rm -rf flutter
            git clone https://github.com/flutter/flutter.git -b stable --depth 1
        }
    else
        echo "  ✅ Flutter ya tiene Dart >= 3.10.4"
    fi
    
    echo "  📋 Versión de Flutter instalada:"
    flutter --version
ENDSSH

echo "  ✅ Flutter listo"
echo ""

# ============================================================================
# PASO 7: Compilar Flutter Web
# ============================================================================

echo "🏗️  Paso 7: Compilando Flutter Web (modo release)..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    PORTAL_DIR="/home/ec2-user/\${REPO_NAME}/shopping_exercise_portal"
    
    export PATH="\$PATH:/home/ec2-user/flutter/bin"
    
    echo "  → Navegando a directorio del portal..."
    if [ ! -d "\$PORTAL_DIR" ]; then
        echo "  ❌ ERROR: Directorio no encontrado: \$PORTAL_DIR"
        exit 1
    fi
    
    cd "\$PORTAL_DIR"
    echo "  ✅ Directorio actual: \$(pwd)"
    
    echo "  → Obteniendo dependencias..."
    flutter pub get || {
        echo "  ❌ ERROR: Falló flutter pub get"
        exit 1
    }
    
    echo "  → Compilando para web (release)..."
    # Intentar con --wasm primero (Flutter 3.x+), luego sin él
    if flutter build web --release --wasm 2>&1; then
        echo "  ✅ Compilación completada con --wasm"
    elif flutter build web --release 2>&1; then
        echo "  ✅ Compilación completada (sin --wasm)"
    else
        echo "  ❌ ERROR: Falló la compilación de Flutter"
        echo "  💡 Verificando directorio build..."
        ls -la build/ 2>/dev/null || echo "  (Directorio build no existe)"
        exit 1
    fi
    
    # Verificar que el directorio build/web existe
    if [ ! -d "build/web" ]; then
        echo "  ❌ ERROR: Directorio build/web no existe después de la compilación"
        echo "  💡 Contenido del directorio build:"
        ls -la build/ 2>/dev/null || echo "  (Directorio build no existe)"
        exit 1
    fi
    
    echo "  ✅ Directorio build/web verificado"
    echo "  📁 Contenido de build/web:"
    ls -la build/web/ | head -10
ENDSSH

echo "  ✅ Build completado"
echo ""

# ============================================================================
# PASO 8: Configurar nginx para /portal
# ============================================================================

echo "🌐 Paso 8: Configurando nginx para /portal..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    PORTAL_DIR="/home/ec2-user/\${REPO_NAME}/shopping_exercise_portal"
    NGINX_PORTAL_DIR="/var/www/html/portal"
    
    echo "  → Verificando que build/web existe..."
    if [ ! -d "\$PORTAL_DIR/build/web" ]; then
        echo "  ❌ ERROR: Directorio build/web no existe en \$PORTAL_DIR"
        echo "  💡 Verificando estructura del proyecto:"
        ls -la "\$PORTAL_DIR/" | head -10
        exit 1
    fi
    
    echo "  → Copiando archivos build a nginx..."
    sudo mkdir -p "\$NGINX_PORTAL_DIR"
    
    # Limpiar directorio destino si existe
    sudo rm -rf "\$NGINX_PORTAL_DIR"/*
    
    # Copiar archivos (usar . para copiar todo el contenido)
    sudo cp -r "\$PORTAL_DIR/build/web/." "\$NGINX_PORTAL_DIR/" || {
        echo "  ❌ ERROR: No se pudieron copiar los archivos"
        echo "  💡 Verificando permisos y contenido:"
        ls -la "\$PORTAL_DIR/build/web/" | head -10
        exit 1
    }
    
    sudo chown -R nginx:nginx "\$NGINX_PORTAL_DIR"
    echo "  ✅ Archivos copiados correctamente"
    echo "  📁 Contenido de \$NGINX_PORTAL_DIR:"
    ls -la "\$NGINX_PORTAL_DIR" | head -10
    
    echo "  → Actualizando configuración de nginx..."
    # Leer configuración actual y agregar /portal si no existe
    if ! sudo grep -q "location /portal" /etc/nginx/conf.d/shopping-app.conf 2>/dev/null; then
        # Agregar configuración de /portal antes del cierre del server block
        sudo sed -i '/^}$/i\
    # Flutter Portal en /portal\
    location /portal {\
        alias /var/www/html/portal;\
        try_files \$uri \$uri/ /portal/index.html;\
        index index.html;\
    }' /etc/nginx/conf.d/shopping-app.conf
    fi
    
    echo "  → Probando configuración de nginx..."
    sudo nginx -t
    
    echo "  → Reiniciando nginx..."
    sudo systemctl restart nginx
    
    echo "  ✅ nginx configurado para /portal"
ENDSSH

echo "  ✅ nginx configurado"
echo ""

# ============================================================================
# RESUMEN
# ============================================================================

echo "=========================================="
echo "✅ Deployment del Portal Flutter completado!"
echo ""
echo "📍 Información de la instancia:"
echo "   Instance ID: $INSTANCE_ID"
echo "   IP Pública: $PUBLIC_IP"
echo "   Usuario SSH: ec2-user"
echo "   Key File: $KEY_FILE"
echo ""
echo "🌐 🌐 🌐 TU PORTAL FLUTTER ESTÁ DISPONIBLE EN: 🌐 🌐 🌐"
echo ""
echo "   👉 Portal: http://${PUBLIC_IP}/portal 👈"
echo ""
echo "📝 Nota: El portal está en la misma instancia que el backend y la app"
echo "   Backend API: http://${PUBLIC_IP}/api"
echo "   App Flutter: http://${PUBLIC_IP}/app"
echo "   Portal Flutter: http://${PUBLIC_IP}/portal"
echo ""
echo "=========================================="

