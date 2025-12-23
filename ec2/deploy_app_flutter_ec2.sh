#!/bin/bash

###############################################################################
# SCRIPT DE DEPLOYMENT - APP FLUTTER A EC2 CON NGINX
###############################################################################
#
# Este script:
# 1. Compila Flutter Web localmente en modo release
# 2. Hace commit y push de los archivos compilados
# 3. Busca la instancia EC2 "shopping-app" (compartida con backend)
# 4. Se conecta por SSH
# 5. Actualiza el código desde GitHub
# 6. Configura nginx para servir la app en /app
#
# CONFIGURACIÓN REQUERIDA:
# =======================
# 1. AWS_REGION: Región de AWS (ej: us-east-1)
# 2. KEY_PAIR_NAME: Nombre del key pair de AWS
# 3. GITHUB_REPO_URL: URL del repositorio GitHub
# 4. GITHUB_TOKEN (opcional): Token de acceso
# 5. EC2_INSTANCE_NAME: Debe ser "shopping-app" (compartida con backend)
#
###############################################################################

set -e

# ============================================================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================================================

AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_PAIR_NAME="aws-eb-shopping-exercise"  # ⚠️ REQUERIDO: Nombre de tu key pair de AWS
EC2_INSTANCE_NAME="shopping-app"  # Nombre para la instancia (compartida con backend y portal)
GITHUB_REPO_URL="git@github.com:cyberfanta/shopping_exercise.git"  # ⚠️ REQUERIDO: URL del repo
GITHUB_TOKEN=""            # Opcional: Token para repos privados

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

echo "🚀 Iniciando deployment de la App Flutter a EC2"
echo "================================================"
echo "Región: $AWS_REGION"
echo "Instance Name: $EC2_INSTANCE_NAME"
echo "Key Pair: $KEY_PAIR_NAME"
echo ""

# ============================================================================
# PASO 0: Compilar Flutter localmente y hacer commit
# ============================================================================

echo "🏗️  Paso 0: Compilando Flutter localmente..."

# Detectar directorio del proyecto (puede ejecutarse desde /ec2 o desde raíz)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$SCRIPT_DIR" == *"/ec2" ]]; then
    # Si se ejecuta desde /ec2, subir un nivel
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    PROJECT_ROOT="$(pwd)"
fi

APP_DIR="$PROJECT_ROOT/shopping_exercise_app"

echo "  📁 Directorio del proyecto: $PROJECT_ROOT"
echo "  📁 Directorio de la app: $APP_DIR"

# Verificar que el directorio existe
if [ ! -d "$APP_DIR" ]; then
    echo "  ❌ ERROR: No se encontró el directorio de la app: $APP_DIR"
    echo "  💡 Asegúrate de ejecutar el script desde la raíz del proyecto o desde /ec2"
    exit 1
fi

# Verificar que Flutter está instalado localmente
if ! command -v flutter &> /dev/null; then
    echo "  ❌ ERROR: Flutter no está instalado en tu sistema local"
    echo "  💡 Instala Flutter desde: https://flutter.dev/docs/get-started/install"
    exit 1
fi

cd "$APP_DIR"

echo "  → Obteniendo dependencias..."
flutter pub get || {
    echo "  ❌ ERROR: Falló flutter pub get"
    exit 1
}

echo "  → Compilando para web (release) con base-href=/app/..."
# Compilar con --base-href para que funcione correctamente desde /app
# Usar MSYS_NO_PATHCONV para evitar que Git Bash convierta rutas en Windows
BASE_HREF="/app/"
# Intentar con --wasm primero, luego sin él
if MSYS_NO_PATHCONV=1 flutter build web --release --base-href="$BASE_HREF" 2>&1; then
    echo "  ✅ Compilación completada con base-href=$BASE_HREF"
elif MSYS_NO_PATHCONV=1 flutter build web --release --wasm --base-href="$BASE_HREF" 2>&1; then
    echo "  ✅ Compilación completada con --wasm con base-href=$BASE_HREF"
else
    echo "  ❌ ERROR: Falló la compilación de Flutter"
    exit 1
fi

# Verificar que build/web existe
if [ ! -d "build/web" ]; then
    echo "  ❌ ERROR: Directorio build/web no existe después de la compilación"
    exit 1
fi

echo "  ✅ Build completado localmente"

# Hacer commit y push de los archivos compilados
echo "  → Haciendo commit de los archivos compilados..."
cd "$PROJECT_ROOT"

# Verificar que estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo "  ❌ ERROR: No se encontró un repositorio git en $PROJECT_ROOT"
    exit 1
fi

# Agregar archivos build/web
git add shopping_exercise_app/build/web/ || {
    echo "  ⚠️  No se pudieron agregar archivos (puede que no haya cambios)"
}

# Verificar si hay cambios para commitear
if git diff --staged --quiet; then
    echo "  ℹ️  No hay cambios nuevos para commitear"
else
    echo "  → Creando commit..."
    git commit -m "Build app Flutter web (release)" || {
        echo "  ⚠️  No se pudo crear el commit (puede que no haya cambios)"
    }
    
    echo "  → Haciendo push a GitHub..."
    git push origin master 2>&1 || git push origin main 2>&1 || {
        echo "  ⚠️  No se pudo hacer push (puede que no haya cambios o problemas de conexión)"
    }
    echo "  ✅ Cambios commiteados y pusheados"
fi

echo "  ✅ Compilación y commit completados"
echo ""

# ============================================================================
# PASO 1: Buscar o crear instancia EC2
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
# PASO 5: Instalar dependencias del sistema (Git y Nginx)
# ============================================================================

echo "📦 Paso 5: Instalando dependencias del sistema..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    echo "  → Verificando e instalando dependencias..."
    
    # Verificar e instalar Git
    if ! command -v git &> /dev/null; then
        echo "  → Actualizando sistema..."
        sudo dnf update -y -q
        echo "  → Instalando Git..."
        sudo dnf install -y -q git
    else
        echo "  ✅ Git ya está instalado"
    fi
    
    # Verificar e instalar Nginx
    if ! command -v nginx &> /dev/null; then
        echo "  → Instalando Nginx..."
        sudo dnf install -y -q nginx
        echo "  → Iniciando Nginx..."
        sudo systemctl start nginx
        sudo systemctl enable nginx
    else
        echo "  ✅ Nginx ya está instalado"
        if ! sudo systemctl is-active --quiet nginx; then
            echo "  → Iniciando Nginx..."
            sudo systemctl start nginx
        fi
    fi
    
    echo "  ✅ Dependencias instaladas"
ENDSSH

echo "  ✅ Dependencias instaladas"
echo ""

# ============================================================================
# PASO 6: Actualizar código desde GitHub
# ============================================================================

echo "📥 Paso 6: Actualizando código desde GitHub..."

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
        git reset --hard origin/master 2>&1 || git reset --hard origin/main 2>&1 || true
        git clean -fd 2>&1 || true
        
        # Intentar pull
        git pull origin master 2>&1 || git pull origin main 2>&1 || true
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
# PASO 7: Copiar archivos compilados y configurar nginx para /app
# ============================================================================

echo "🌐 Paso 7: Copiando archivos compilados y configurando nginx para /app..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    APP_DIR="/home/ec2-user/\${REPO_NAME}/shopping_exercise_app"
    NGINX_APP_DIR="/var/www/html/app"
    
    echo "  → Verificando estructura del repositorio..."
    echo "  📁 Repositorio: /home/ec2-user/\$REPO_NAME"
    
    # Verificar que el repositorio existe
    if [ ! -d "/home/ec2-user/\$REPO_NAME" ]; then
        echo "  ❌ ERROR: Repositorio no encontrado: /home/ec2-user/\$REPO_NAME"
        echo "  💡 Directorios disponibles en /home/ec2-user:"
        ls -la /home/ec2-user/ | head -10
        exit 1
    fi
    
    # Verificar que el directorio de la app existe
    if [ ! -d "\$APP_DIR" ]; then
        echo "  ❌ ERROR: Directorio de la app no encontrado: \$APP_DIR"
        echo "  💡 Contenido del repositorio:"
        ls -la "/home/ec2-user/\$REPO_NAME" | head -15
        exit 1
    fi
    
    echo "  ✅ Directorio de la app encontrado: \$APP_DIR"
    
    # Verificar que build/web existe
    echo "  → Verificando que los archivos compilados existan..."
    if [ ! -d "\$APP_DIR/build/web" ]; then
        echo "  ❌ ERROR: Directorio build/web no encontrado en \$APP_DIR"
        echo "  💡 Estructura del directorio de la app:"
        ls -la "\$APP_DIR" | head -15
        if [ -d "\$APP_DIR/build" ]; then
            echo "  💡 Contenido de build:"
            ls -la "\$APP_DIR/build" | head -10
        else
            echo "  💡 El directorio build no existe"
        fi
echo ""
        echo "  💡 Asegúrate de haber compilado la app en tu laptop y commiteado los archivos"
        echo "  💡 Ejecuta: cd shopping_exercise_app && flutter build web --release"
        echo "  💡 Luego commitea: git add build/web && git commit -m 'Build app' && git push"
        exit 1
    fi
    
    echo "  ✅ Archivos compilados encontrados en \$APP_DIR/build/web"
    
    # Crear directorio de nginx para la app
    echo "  → Creando directorio en nginx..."
    sudo mkdir -p "\$NGINX_APP_DIR"
    
    # Limpiar directorio destino si existe
    sudo rm -rf "\$NGINX_APP_DIR"/*
    
    # Copiar archivos compilados
    echo "  → Copiando archivos compilados a nginx..."
    sudo cp -r "\$APP_DIR/build/web/." "\$NGINX_APP_DIR/" || {
        echo "  ❌ ERROR: No se pudieron copiar los archivos"
        echo "  💡 Verificando permisos y contenido:"
        ls -la "\$APP_DIR/build/web/" | head -10
        exit 1
    }
    
    sudo chown -R nginx:nginx "\$NGINX_APP_DIR"
    echo "  ✅ Archivos copiados correctamente a \$NGINX_APP_DIR"
    
    # Verificar que index.html existe
    if [ ! -f "\$NGINX_APP_DIR/index.html" ]; then
        echo "  ❌ ERROR: index.html no encontrado en \$NGINX_APP_DIR"
        echo "  💡 Contenido del directorio:"
        ls -la "\$NGINX_APP_DIR" | head -15
        exit 1
    fi
    
    echo "  ✅ index.html encontrado"
    
    # Verificar que el base-href se aplicó correctamente en index.html
    echo "  → Verificando base-href en index.html..."
    if grep -q 'base href="/app/"' "\$NGINX_APP_DIR/index.html" 2>/dev/null; then
        echo "  ✅ base-href correcto en index.html"
    else
        echo "  ⚠️  ADVERTENCIA: base-href puede no estar configurado correctamente"
        echo "  💡 Contenido de base tag en index.html:"
        grep -i 'base href' "\$NGINX_APP_DIR/index.html" || echo "  (No se encontró base tag)"
    fi
    
    echo "  📁 Contenido de \$NGINX_APP_DIR:"
    ls -la "\$NGINX_APP_DIR" | head -10
    
    echo "  → Actualizando configuración de nginx..."
    
    # Limpiar otras configuraciones que puedan causar conflicto
    echo "  → Limpiando configuraciones antiguas de nginx..."
    sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true
    sudo rm -f /etc/nginx/conf.d/flutter-app.conf 2>/dev/null || true
    sudo rm -f /etc/nginx/conf.d/flutter-portal.conf 2>/dev/null || true
    
    # Crear configuración completa de nginx
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
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_cache_bypass \$http_upgrade;
        
        # Headers para CORS (si el backend no los maneja completamente)
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        
        # Manejar preflight OPTIONS
        if (\$request_method = OPTIONS) {
            return 204;
        }
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings para peticiones grandes
        proxy_buffering off;
        proxy_request_buffering off;
    }
    
    # Health check directo (sin /api)
    location = /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # Adminer - Database Management UI en /adminer
    location /adminer/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Redirect /adminer to /adminer/
    location = /adminer {
        return 301 /adminer/;
    }
    
    # No cachear index.html de la app
    location = /app/index.html {
        root /var/www/html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Servir archivos estáticos de Flutter con cache largo
    location ~* ^/app/(assets|canvaskit|icons)/ {
        root /var/www/html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Servir archivos JS y WASM de Flutter
    location ~* ^/app/.*\.(js|wasm)$ {
        root /var/www/html;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Content-Type "application/javascript" always;
    }
    
    # Flutter App en /app
    location /app {
        root /var/www/html;
        try_files \$uri \$uri/ /app/index.html;
        index index.html;
        
        # Headers importantes para Flutter
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
    }
    
    # Flutter Portal en /portal (si existe)
    location /portal {
        root /var/www/html;
        try_files \$uri \$uri/ /portal/index.html;
        index index.html;
        
        # Headers para archivos estáticos
        add_header Cache-Control "public, max-age=31536000, immutable" always;
    }
    
    # Servir archivos estáticos de Flutter Portal (assets, canvaskit, etc.)
    location ~* ^/portal/(assets|canvaskit|icons)/ {
        root /var/www/html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Redirigir raíz a /app
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
    
    echo "  → Probando configuración de nginx..."
    sudo nginx -t
    
    echo "  → Reiniciando nginx..."
    sudo systemctl restart nginx
    
    echo "  → Verificando que el backend esté accesible..."
    sleep 2
    if curl -s -f -m 5 http://localhost:3000/health >/dev/null 2>&1; then
        echo "  ✅ Backend responde en localhost:3000"
    else
        echo "  ⚠️  ADVERTENCIA: Backend no responde en localhost:3000"
        echo "  💡 Verifica que los contenedores Docker estén corriendo:"
        echo "     sudo docker ps"
        echo "     sudo docker logs shopping_api"
    fi
    
    echo "  → Verificando que el proxy funcione..."
    if curl -s -f -m 5 http://localhost/api/health >/dev/null 2>&1; then
        echo "  ✅ Proxy de nginx funciona correctamente"
    else
        echo "  ⚠️  ADVERTENCIA: Proxy de nginx no responde"
        echo "  💡 Verifica la configuración de nginx:"
        echo "     sudo nginx -t"
        echo "     sudo tail -f /var/log/nginx/error.log"
    fi
    
    echo "  ✅ nginx configurado para /app"
ENDSSH

echo "  ✅ nginx configurado"
echo ""

# ============================================================================
# RESUMEN
# ============================================================================

echo "=========================================="
echo "✅ Deployment de la App Flutter completado!"
echo ""
echo "📍 Información de la instancia:"
echo "   Instance ID: $INSTANCE_ID"
echo "   IP Pública: $PUBLIC_IP"
echo "   Usuario SSH: ec2-user"
echo "   Key File: $KEY_FILE"
echo ""
echo "🌐 🌐 🌐 TU APP FLUTTER ESTÁ DISPONIBLE EN: 🌐 🌐 🌐"
echo ""
echo "   👉 App: http://${PUBLIC_IP}/app 👈"
echo ""
echo "📝 Nota: La app está en la misma instancia que el backend"
echo "   Backend API: http://${PUBLIC_IP}/api"
echo "   App Flutter: http://${PUBLIC_IP}/app"
echo ""
echo "=========================================="

