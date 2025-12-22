#!/bin/bash

###############################################################################
# SCRIPT DE DEPLOYMENT - APP FLUTTER A EC2 CON NGINX
###############################################################################
#
# Este script:
# 1. Crea una instancia EC2 t3.micro
# 2. Configura security group (SSH, HTTP, HTTPS)
# 3. Se conecta por SSH
# 4. Verifica acceso a GitHub
# 5. Clona el repositorio
# 6. Compila Flutter en modo release
# 7. Configura nginx para servir la app
#
# CONFIGURACIÓN REQUERIDA:
# =======================
# 1. AWS_REGION: Región de AWS (ej: us-east-1)
# 2. KEY_PAIR_NAME: Nombre del key pair de AWS
# 3. GITHUB_REPO_URL: URL del repositorio GitHub
# 4. GITHUB_TOKEN (opcional): Token de acceso
# 5. EC2_INSTANCE_NAME: Nombre para la instancia (ej: shopping-app)
#
###############################################################################

set -e

# ============================================================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================================================

AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_PAIR_NAME="aws-eb-shopping-exercise"  # ⚠️ REQUERIDO: Nombre de tu key pair de AWS
EC2_INSTANCE_NAME="shopping-flutter"  # Nombre para la instancia (compartida con portal)
GITHUB_REPO_URL="git@github.com:cyberfanta/shopping_exercise.git"  # ⚠️ REQUERIDO: URL del repo
GITHUB_TOKEN=""            # Opcional: Token para repos privados
INSTANCE_TYPE="t3.micro"   # Tipo de instancia
AMI_ID=""                  # Dejar vacío para usar Amazon Linux 2023
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

wait_for_ssh() {
    local host=$1
    local max_attempts=30
    local attempt=0
    
    # Determinar el archivo de clave correcto
    local key_file="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
    if [ ! -f "$key_file" ]; then
        key_file="$HOME/.ssh/${KEY_PAIR_NAME}"
    fi
    
    echo "  ⏳ Esperando a que SSH esté disponible..."
    while [ $attempt -lt $max_attempts ]; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
           -i "$key_file" ec2-user@${host} "echo 'SSH ready'" 2>/dev/null; then
            echo "  ✅ SSH disponible"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 10
    done
    
    echo "  ❌ Timeout esperando SSH"
    return 1
}

# ============================================================================
# INICIO DEL DEPLOYMENT
# ============================================================================

echo "🚀 Iniciando deployment de la App Flutter a EC2"
echo "==============================================="
echo "Región: $AWS_REGION"
echo "Instance Type: $INSTANCE_TYPE"
echo "Key Pair: $KEY_PAIR_NAME"
echo ""

# ============================================================================
# PASO 1: Crear Security Group
# ============================================================================

echo "📋 Paso 1: Creando Security Group..."

SG_NAME="${EC2_INSTANCE_NAME}-sg"
SG_DESCRIPTION="Security group for ${EC2_INSTANCE_NAME}"

EXISTING_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${SG_NAME}" \
    --region "$AWS_REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null)

if [ "$EXISTING_SG" != "None" ] && [ -n "$EXISTING_SG" ]; then
    echo "  ✅ Security Group ya existe: $EXISTING_SG"
    SG_ID="$EXISTING_SG"
else
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SG_NAME" \
        --description "$SG_DESCRIPTION" \
        --region "$AWS_REGION" \
        --query 'GroupId' \
        --output text)
    
    echo "  ✅ Security Group creado: $SG_ID"
    
    # Agregar reglas
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr "$ALLOWED_SSH_IP" \
        --region "$AWS_REGION" >/dev/null 2>&1
    
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" >/dev/null 2>&1
    
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" >/dev/null 2>&1
    
    echo "  ✅ Reglas agregadas (SSH:22 desde $ALLOWED_SSH_IP, HTTP:80, HTTPS:443)"
fi

echo ""

# ============================================================================
# PASO 2: Obtener AMI
# ============================================================================

echo "🔍 Paso 2: Obteniendo AMI de Amazon Linux 2023..."

if [ -z "$AMI_ID" ]; then
    AMI_ID=$(aws ec2 describe-images \
        --owners amazon \
        --filters "Name=name,Values=al2023-ami-2023.*-x86_64" "Name=state,Values=available" \
        --region "$AWS_REGION" \
        --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
        --output text)
fi

echo "  ✅ AMI seleccionada: $AMI_ID"
echo ""

# ============================================================================
# PASO 3: Crear Instancia EC2
# ============================================================================

echo "🖥️  Paso 3: Creando instancia EC2..."

EXISTING_INSTANCE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${EC2_INSTANCE_NAME}" "Name=instance-state-name,Values=running,stopped,stopping" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

if [ "$EXISTING_INSTANCE" != "None" ] && [ -n "$EXISTING_INSTANCE" ]; then
    echo "  ⚠️  Instancia ya existe: $EXISTING_INSTANCE"
    aws ec2 start-instances --instance-ids "$EXISTING_INSTANCE" --region "$AWS_REGION" >/dev/null
    INSTANCE_ID="$EXISTING_INSTANCE"
else
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_PAIR_NAME" \
        --security-group-ids "$SG_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${EC2_INSTANCE_NAME}}]" \
        --region "$AWS_REGION" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    echo "  ✅ Instancia creada: $INSTANCE_ID"
fi

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "  ✅ Instancia lista"
echo "  📍 IP Pública: $PUBLIC_IP"
echo ""

# ============================================================================
# PASO 4: Configurar SSH
# ============================================================================

echo "🔐 Paso 4: Configurando SSH..."

# Verificar que existe el archivo de clave (puede ser .pem o sin extensión para ed25519)
KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
if [ ! -f "$KEY_FILE" ]; then
    # Intentar sin extensión .pem (común para ed25519)
    KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}"
    if [ ! -f "$KEY_FILE" ]; then
        # Intentar buscar en la carpeta del proyecto
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
        KEY_FILE_PROJECT="$PROJECT_ROOT/${KEY_PAIR_NAME}.pem"
        
        if [ -f "$KEY_FILE_PROJECT" ]; then
            echo "  ✅ Clave encontrada en el proyecto: $KEY_FILE_PROJECT"
            KEY_FILE="$KEY_FILE_PROJECT"
            # Copiar a ~/.ssh/ para uso estándar
            mkdir -p "$HOME/.ssh"
            cp "$KEY_FILE" "$HOME/.ssh/${KEY_PAIR_NAME}.pem"
            KEY_FILE="$HOME/.ssh/${KEY_PAIR_NAME}.pem"
            echo "  ✅ Clave copiada a: $KEY_FILE"
        else
            echo "  ❌ ERROR: No se encuentra el archivo de clave"
            echo "  💡 Buscando en:"
            echo "     - $HOME/.ssh/${KEY_PAIR_NAME}.pem"
            echo "     - $HOME/.ssh/${KEY_PAIR_NAME}"
            echo "     - $KEY_FILE_PROJECT"
            exit 1
        fi
    fi
fi

chmod 400 "$KEY_FILE" 2>/dev/null || true

# Agregar clave al agente SSH
echo "  → Agregando clave al agente SSH..."
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add "$KEY_FILE" 2>/dev/null || {
    echo "  ⚠️  No se pudo agregar al agente SSH (puede que ya esté agregada)"
}

echo "  ✅ Clave configurada: $KEY_FILE"

wait_for_ssh "$PUBLIC_IP"

echo ""

# ============================================================================
# PASO 5: Instalar dependencias (Flutter, nginx, etc.)
# ============================================================================

echo "📦 Paso 5: Instalando dependencias..."

# Crear archivo de historial de comandos
HISTORY_FILE="/tmp/ec2_deployment_history_$(date +%Y%m%d_%H%M%S).log"
echo "📝 Historial de comandos se guardará en: $HISTORY_FILE"
echo ""

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << 'ENDSSH' | tee -a "$HISTORY_FILE"
    set -e
    
    echo "  → Verificando e instalando dependencias..."
    
    # Verificar e instalar Git y herramientas básicas
    if ! command -v git &> /dev/null; then
        echo "  → Actualizando sistema..."
        sudo dnf update -y -q
        echo "  → Instalando herramientas básicas..."
        sudo dnf install -y -q git curl unzip wget
    else
        echo "  ✅ Git y herramientas básicas ya están instaladas"
    fi
    
    # Verificar e instalar nginx
    if ! command -v nginx &> /dev/null; then
        echo "  → Instalando nginx..."
        sudo dnf install -y -q nginx
        sudo systemctl enable nginx
    else
        echo "  ✅ nginx ya está instalado"
        # Asegurar que nginx esté habilitado
        sudo systemctl enable nginx 2>/dev/null || true
    fi
    
    # Verificar e instalar Flutter
    echo "  → Verificando Flutter..."
    cd /home/ec2-user
    if [ ! -d "flutter" ]; then
        echo "  → Instalando Flutter..."
        git clone https://github.com/flutter/flutter.git -b stable --depth 1
        export PATH="$PATH:/home/ec2-user/flutter/bin"
        echo 'export PATH="$PATH:/home/ec2-user/flutter/bin"' >> ~/.bashrc
    else
        echo "  ✅ Flutter ya está instalado, actualizando..."
        export PATH="$PATH:/home/ec2-user/flutter/bin"
        cd flutter
        git fetch origin || true
        git pull origin stable || git pull || true
        cd ..
    fi
    
    # Verificar que Flutter esté en el PATH
    export PATH="$PATH:/home/ec2-user/flutter/bin"
    if ! command -v flutter &> /dev/null; then
        echo "  ⚠️  Flutter no está en PATH, agregando..."
        export PATH="$PATH:/home/ec2-user/flutter/bin"
    fi
    
    echo "  → Configurando Flutter..."
    flutter doctor --android-licenses <<< "y" || true
    flutter precache --web || true
    
    echo "  ✅ Dependencias verificadas/instaladas"
    echo ""
    echo "  📋 Versiones instaladas:"
    echo "     Git: $(git --version 2>/dev/null | awk '{print $3}' || echo 'N/A')"
    echo "     Flutter: $(flutter --version 2>/dev/null | head -1 | awk '{print $2}' || echo 'N/A')"
ENDSSH

echo "  ✅ Configuración completada"
echo "  📝 Historial guardado en: $HISTORY_FILE"
echo ""

# ============================================================================
# PASO 6: Clonar repositorio
# ============================================================================

echo "🔗 Paso 6: Clonando repositorio..."

# Detectar tipo de URL (SSH o HTTPS) y preparar para clonar
if echo "$GITHUB_REPO_URL" | grep -q "^git@"; then
    # URL SSH - convertir a HTTPS para clonar desde EC2
    REPO_PATH=$(echo "$GITHUB_REPO_URL" | sed 's|git@github.com:||' | sed 's|\.git$||')
    if [ -n "$GITHUB_TOKEN" ]; then
        GITHUB_REPO_URL_WITH_AUTH="https://${GITHUB_TOKEN}@github.com/${REPO_PATH}.git"
    else
        # Usar HTTPS público si no hay token
        GITHUB_REPO_URL_WITH_AUTH="https://github.com/${REPO_PATH}.git"
    fi
    REPO_NAME=$(basename "$REPO_PATH")
else
    # URL HTTPS
    if [ -n "$GITHUB_TOKEN" ]; then
        GITHUB_REPO_URL_WITH_AUTH=$(echo "$GITHUB_REPO_URL" | sed "s|https://|https://${GITHUB_TOKEN}@|")
    else
        GITHUB_REPO_URL_WITH_AUTH="$GITHUB_REPO_URL"
    fi
    REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)
fi

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    GITHUB_REPO_URL_WITH_AUTH="$GITHUB_REPO_URL_WITH_AUTH"
    
    echo "  → Verificando acceso a GitHub..."
    if curl -s -o /dev/null -w "%{http_code}" https://github.com | grep -q "200"; then
        echo "  ✅ Acceso a GitHub disponible"
    else
        echo "  ⚠️  No se pudo verificar acceso a GitHub, pero continuando..."
    fi
    
    echo "  → Clonando/actualizando repositorio..."
    cd /home/ec2-user
    
    # Verificar si el directorio existe y tiene contenido válido
    if [ -d "\$REPO_NAME" ] && [ -d "\$REPO_NAME/.git" ]; then
        echo "  → El repositorio ya existe, actualizando..."
        cd "\$REPO_NAME"
        git fetch origin || true
        # Intentar pull de main primero, luego master
        if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || git pull 2>/dev/null; then
            echo "  ✅ Repositorio actualizado"
        else
            echo "  ⚠️  No se pudo hacer pull, pero continuando..."
        fi
        cd ..
    else
        echo "  → Clonando repositorio..."
        if [ -d "\$REPO_NAME" ]; then
            echo "  → Eliminando directorio existente sin git..."
            rm -rf "\$REPO_NAME"
        fi
        git clone "\$GITHUB_REPO_URL_WITH_AUTH" "\$REPO_NAME" || {
            echo "  ❌ Error al clonar repositorio"
            echo "  💡 Verifica que el repositorio existe y que tienes acceso"
            echo "  💡 URL: \$GITHUB_REPO_URL_WITH_AUTH"
            exit 1
        }
        echo "  ✅ Repositorio clonado"
    fi
    
    # Verificar que el directorio de la app existe
    if [ ! -d "\$REPO_NAME/shopping_exercise_app" ]; then
        echo "  ❌ ERROR: Directorio shopping_exercise_app no encontrado en \$REPO_NAME"
        echo "  💡 Contenido de \$REPO_NAME:"
        ls -la "\$REPO_NAME" 2>/dev/null || echo "  (Directorio no existe)"
        exit 1
    fi
    
    echo "  ✅ Repositorio listo"
    echo "  📁 Ubicación: /home/ec2-user/\$REPO_NAME/shopping_exercise_app"
ENDSSH

echo "  ✅ Repositorio clonado"
echo ""

# ============================================================================
# PASO 7: Compilar Flutter Web
# ============================================================================

echo "🏗️  Paso 7: Compilando Flutter Web (modo release)..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH
    set -e
    
    export PATH="$PATH:/home/ec2-user/flutter/bin"
    REPO_NAME="$REPO_NAME"
    APP_DIR="/home/ec2-user/\${REPO_NAME}/shopping_exercise_app"
    
    export PATH="$PATH:/home/ec2-user/flutter/bin"
    
    echo "  → Navegando a directorio de la app..."
    if [ ! -d "\$APP_DIR" ]; then
        echo "  ❌ ERROR: Directorio no encontrado: \$APP_DIR"
        echo "  💡 Directorios disponibles en /home/ec2-user/\$REPO_NAME:"
        ls -la "/home/ec2-user/\$REPO_NAME" 2>/dev/null | head -10 || echo "  (Directorio no existe)"
        exit 1
    fi
    
    cd "\$APP_DIR"
    echo "  ✅ Directorio actual: \$(pwd)"
    
    echo "  → Obteniendo dependencias..."
    flutter pub get
    
    echo "  → Compilando para web (release)..."
    flutter build web --release
    
    echo "  ✅ Compilación completada"
ENDSSH

echo "  ✅ Build completado"
echo "  📝 Historial actualizado en: $HISTORY_FILE"
echo ""

# ============================================================================
# PASO 8: Configurar nginx
# ============================================================================

echo "🌐 Paso 8: Configurando nginx..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    
    echo "  → Actualizando configuración de nginx (agregando app Flutter)..."
    
    # Configuración completa de nginx: backend + app + portal
    sudo tee /etc/nginx/conf.d/shopping-app.conf > /dev/null << 'NGINXCONF'
server {
    listen 80;
    server_name _;
    
    # Backend API en /api
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Health check directo
    location /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # App Flutter en /app
    location /app {
        alias /home/ec2-user/$REPO_NAME/shopping_exercise_app/build/web;
        index index.html;
        try_files \$uri \$uri/ /app/index.html;
        
        # Cache static assets
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Portal Flutter en /portal (si existe)
    location /portal {
        alias /home/ec2-user/$REPO_NAME/shopping_exercise_portal/build/web;
        index index.html;
        try_files \$uri \$uri/ /portal/index.html;
        
        # Cache static assets
        location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Redirigir raíz a /app por defecto
    location = / {
        return 301 /app;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
NGINXCONF
    
    # Reemplazar variable en el archivo
    sudo sed -i "s|\\\$REPO_NAME|\$REPO_NAME|g" /etc/nginx/conf.d/shopping-app.conf
    
    # Eliminar configuraciones antiguas si existen
    sudo rm -f /etc/nginx/conf.d/flutter-app.conf /etc/nginx/conf.d/flutter-portal.conf /etc/nginx/conf.d/flutter-apps.conf 2>/dev/null || true
    
    echo "  → Probando configuración de nginx..."
    sudo nginx -t
    
    echo "  → Iniciando nginx..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    echo "  ✅ nginx configurado y corriendo"
ENDSSH

echo "  ✅ nginx configurado"
echo "  📝 Historial completo guardado en: $HISTORY_FILE"
echo ""

# ============================================================================
# RESUMEN
# ============================================================================

echo "==============================================="
echo "✅ Deployment de la App Flutter completado!"
echo ""
echo "📍 Información de la instancia:"
echo "   Instance ID: $INSTANCE_ID"
echo "   IP Pública: $PUBLIC_IP"
echo "   Usuario SSH: ec2-user"
echo "   Key File: $KEY_FILE"
echo ""
echo "🌐 🌐 🌐 TUS APPS ESTÁN DISPONIBLES EN: 🌐 🌐 🌐"
echo ""
echo "   👉 Backend API: http://${PUBLIC_IP}/api 👈"
echo "   👉 App Flutter: http://${PUBLIC_IP}/app 👈"
echo "   👉 Portal Flutter: http://${PUBLIC_IP}/portal 👈"
echo ""
echo "   Todo está en la misma instancia EC2"
echo "   (Nota: El portal se configurará cuando ejecutes deploy_portal_flutter_ec2.sh)"
echo ""
echo "🔐 Para conectarte por SSH:"
echo "   ssh -i $KEY_FILE ec2-user@${PUBLIC_IP}"
echo ""
echo "📝 Para ver el historial de comandos ejecutados:"
echo "   cat $HISTORY_FILE"
echo ""
echo "🔍 Para verificar el estado de nginx:"
echo "   ssh -i $KEY_FILE ec2-user@${PUBLIC_IP}"
echo "   sudo systemctl status nginx"
echo "   sudo tail -f /var/log/nginx/error.log"
echo "==============================================="

