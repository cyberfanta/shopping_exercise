#!/bin/bash

###############################################################################
# SCRIPT DE DEPLOYMENT - BACKEND A EC2 CON DOCKER
###############################################################################
#
# Este script:
# 1. Crea una instancia EC2 t3.micro
# 2. Configura security group (SSH, puerto interno del backend)
# 3. Se conecta por SSH
# 4. Verifica acceso a GitHub
# 5. Clona el repositorio
# 6. Levanta contenedores Docker (solo internos)
#
# CONFIGURACIÓN REQUERIDA:
# =======================
# 1. AWS_REGION: Región de AWS (ej: us-east-1)
# 2. KEY_PAIR_NAME: Nombre del key pair de AWS (debe existir)
# 3. GITHUB_REPO_URL: URL del repositorio GitHub
# 4. GITHUB_TOKEN (opcional): Token de acceso para repos privados
# 5. EC2_INSTANCE_NAME: Nombre para la instancia EC2
#
###############################################################################

set -e  # Salir si hay error

# ============================================================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================================================

AWS_REGION="${AWS_REGION:-us-east-1}"
KEY_PAIR_NAME="aws-eb-shopping-exercise"  # ⚠️ REQUERIDO: Nombre de tu key pair de AWS
EC2_INSTANCE_NAME="shopping-app"  # Nombre para la instancia (compartida con apps Flutter)
GITHUB_REPO_URL="git@github.com:cyberfanta/shopping_exercise.git"  # ⚠️ REQUERIDO: URL del repositorio GitHub
GITHUB_TOKEN=""            # Opcional: Token para repos privados
INSTANCE_TYPE="t3.micro"   # Tipo de instancia (t3.micro para free tier)
AMI_ID=""                  # Dejar vacío para usar Amazon Linux 2023 por defecto
ALLOWED_SSH_IP="38.74.224.33/32"  # IP permitida para SSH (tu IP actual)

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

# Verificar AWS CLI
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

echo "🚀 Iniciando deployment del Backend a EC2"
echo "=========================================="
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

# Verificar si el security group ya existe
EXISTING_SG=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=${SG_NAME}" \
    --region "$AWS_REGION" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null)

if [ "$EXISTING_SG" != "None" ] && [ -n "$EXISTING_SG" ]; then
    echo "  ✅ Security Group ya existe: $EXISTING_SG"
    SG_ID="$EXISTING_SG"
    
    # Verificar si ya tiene las reglas HTTP/HTTPS
    PORT_80_EXISTS=$(aws ec2 describe-security-groups \
        --group-ids "$SG_ID" \
        --region "$AWS_REGION" \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`]' \
        --output text 2>/dev/null)
    
    if [ -z "$PORT_80_EXISTS" ] || [ "$PORT_80_EXISTS" == "None" ]; then
        echo "  → Agregando reglas HTTP/HTTPS..."
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
        echo "  ✅ Reglas HTTP/HTTPS agregadas"
    else
        echo "  ✅ Reglas HTTP/HTTPS ya existen"
    fi
else
    # Crear security group
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SG_NAME" \
        --description "$SG_DESCRIPTION" \
        --region "$AWS_REGION" \
        --query 'GroupId' \
        --output text)
    
    echo "  ✅ Security Group creado: $SG_ID"
    
    # Agregar regla SSH (puerto 22) solo desde IP permitida
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr "$ALLOWED_SSH_IP" \
        --region "$AWS_REGION" >/dev/null 2>&1
    
    # Agregar reglas HTTP/HTTPS (nginx reverse proxy)
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
    
    echo "  ✅ Regla SSH agregada (puerto 22) desde IP: $ALLOWED_SSH_IP"
    echo "  ✅ Reglas HTTP/HTTPS agregadas (puertos 80/443) desde cualquier IP"
fi

echo ""

# ============================================================================
# PASO 2: Obtener AMI más reciente de Amazon Linux 2023
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

if [ -z "$AMI_ID" ] || [ "$AMI_ID" == "None" ]; then
    echo "  ❌ ERROR: No se pudo obtener AMI"
    exit 1
fi

echo "  ✅ AMI seleccionada: $AMI_ID"
echo ""

# ============================================================================
# PASO 3: Crear Instancia EC2
# ============================================================================

echo "🖥️  Paso 3: Creando instancia EC2..."

# Verificar si la instancia ya existe
EXISTING_INSTANCE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${EC2_INSTANCE_NAME}" "Name=instance-state-name,Values=running,stopped,stopping" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null)

if [ "$EXISTING_INSTANCE" != "None" ] && [ -n "$EXISTING_INSTANCE" ]; then
    echo "  ⚠️  Instancia ya existe: $EXISTING_INSTANCE"
    echo "  → Iniciando instancia existente..."
    aws ec2 start-instances --instance-ids "$EXISTING_INSTANCE" --region "$AWS_REGION" >/dev/null
    INSTANCE_ID="$EXISTING_INSTANCE"
else
    # Crear nueva instancia
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

# Esperar a que la instancia esté running
echo "  ⏳ Esperando a que la instancia esté en estado 'running'..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "  ✅ Instancia lista"
echo "  📍 IP Pública: $PUBLIC_IP"
echo ""

# ============================================================================
# PASO 4: Configurar SSH y conectarse
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
            echo "  💡 Ejecuta: ./scripts/ec2/download_key_pair.sh para verificar"
            exit 1
        fi
    fi
fi

# Dar permisos correctos al archivo de clave
chmod 400 "$KEY_FILE" 2>/dev/null || true

# Agregar clave al agente SSH
echo "  → Agregando clave al agente SSH..."
eval "$(ssh-agent -s)" >/dev/null 2>&1
ssh-add "$KEY_FILE" 2>/dev/null || {
    echo "  ⚠️  No se pudo agregar al agente SSH (puede que ya esté agregada)"
}

echo "  ✅ Clave configurada: $KEY_FILE"

# Esperar a que SSH esté disponible
wait_for_ssh "$PUBLIC_IP"

echo ""

# ============================================================================
# PASO 5: Instalar dependencias y configurar
# ============================================================================

echo "📦 Paso 5: Instalando dependencias en la instancia..."

# Crear archivo de historial de comandos
HISTORY_FILE="/tmp/ec2_deployment_history_$(date +%Y%m%d_%H%M%S).log"
echo "📝 Historial de comandos se guardará en: $HISTORY_FILE"
echo ""

# Función para ejecutar comandos y guardar en historial
run_remote_command() {
    local command="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $command" >> "$HISTORY_FILE"
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} "$command" 2>&1 | tee -a "$HISTORY_FILE"
}

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
    
    # Verificar e instalar Docker
    if ! command -v docker &> /dev/null; then
        echo "  → Instalando Docker..."
        sudo dnf install -y -q docker
        echo "  → Iniciando Docker..."
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "  → Agregando usuario a grupo docker..."
        sudo usermod -aG docker ec2-user
    else
        echo "  ✅ Docker ya está instalado"
        if ! sudo systemctl is-active --quiet docker; then
            echo "  → Iniciando Docker..."
            sudo systemctl start docker
        fi
    fi
    
    # Verificar e instalar Docker Compose (método correcto)
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
        echo "  → Instalando Docker Compose..."
        sudo mkdir -p /usr/local/lib/docker/cli-plugins
        sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" \
            -o /usr/local/lib/docker/cli-plugins/docker-compose
        sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
        sudo ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    else
        echo "  ✅ Docker Compose ya está instalado"
        # Verificar que funcione correctamente
        if ! docker-compose version &> /dev/null 2>&1 && ! docker compose version &> /dev/null 2>&1; then
            echo "  ⚠️  Docker Compose existe pero no funciona, arreglando..."
            # Eliminar instalaciones rotas
            sudo rm -f /usr/local/bin/docker-compose
            sudo rm -f /usr/local/lib/docker/cli-plugins/docker-compose
            
            # Reinstalar correctamente
            sudo mkdir -p /usr/local/lib/docker/cli-plugins
            sudo curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" \
                -o /usr/local/lib/docker/cli-plugins/docker-compose
            sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
            sudo ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
            
            # Verificar que ahora funcione
            if docker compose version &> /dev/null 2>&1 || docker-compose version &> /dev/null 2>&1; then
                echo "  ✅ Docker Compose arreglado correctamente"
            else
                echo "  ⚠️  Docker Compose instalado pero puede requerir reinicio de sesión"
            fi
        fi
    fi
    
    # Instalar y configurar Docker Buildx (requerido para docker compose build)
    echo "  → Verificando Docker Buildx..."
    if ! docker buildx version &> /dev/null 2>&1; then
        echo "  → Instalando Docker Buildx..."
        # Obtener última versión de Buildx
        BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
        
        if [ -z "$BUILDX_VERSION" ] || [ "$BUILDX_VERSION" = "null" ]; then
            BUILDX_VERSION="v0.12.1"  # Fallback a versión estable
            echo "  ⚠️  No se pudo obtener versión, usando: $BUILDX_VERSION"
        else
            echo "  → Versión encontrada: $BUILDX_VERSION"
        fi
        
        # Crear directorio de plugins
        sudo mkdir -p /usr/local/lib/docker/cli-plugins
        
        # Descargar Buildx
        echo "  → Descargando Docker Buildx..."
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
        fi
    else
        echo "  ✅ Docker Buildx ya está instalado"
        docker buildx version
    fi
    
    # Configurar builder (siempre, incluso si ya está instalado)
    echo "  → Configurando builder de Buildx..."
    docker buildx create --name builder --use 2>/dev/null || docker buildx use builder 2>/dev/null || true
    docker buildx inspect --bootstrap 2>/dev/null || true
    echo "  ✅ Builder configurado"
    
    echo "  ✅ Dependencias verificadas/instaladas"
    echo ""
    echo "  📋 Versiones instaladas:"
    DOCKER_VERSION=$(sudo docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo 'N/A')
    COMPOSE_VERSION=$(sudo docker compose version 2>/dev/null | awk '{print $4}' || sudo docker-compose version 2>/dev/null | awk '{print $4}' || echo 'N/A')
    echo "     Docker: $DOCKER_VERSION"
    echo "     Docker Compose: $COMPOSE_VERSION"
ENDSSH

echo "  ✅ Configuración completada"
echo "  📝 Historial guardado en: $HISTORY_FILE"
echo ""

# ============================================================================
# PASO 6: Verificar acceso a GitHub y clonar repositorio
# ============================================================================

echo "🔗 Paso 6: Verificando acceso a GitHub y clonando repositorio..."

# Detectar tipo de URL (SSH o HTTPS) y preparar para clonar
if echo "$GITHUB_REPO_URL" | grep -q "^git@"; then
    # URL SSH - convertir a HTTPS para clonar desde EC2 (o usar SSH si hay keys configuradas)
    # Extraer usuario/repo de formato git@github.com:user/repo.git
    REPO_PATH=$(echo "$GITHUB_REPO_URL" | sed 's|git@github.com:||' | sed 's|\.git$||')
    if [ -n "$GITHUB_TOKEN" ]; then
        GITHUB_REPO_URL_WITH_AUTH="https://${GITHUB_TOKEN}@github.com/${REPO_PATH}.git"
    else
        # Convertir SSH a HTTPS público (más fácil desde EC2)
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
        echo "  → El repositorio ya existe, actualizando desde git..."
        cd "\$REPO_NAME"
        
        # Obtener cambios remotos
        echo "  → Obteniendo cambios remotos..."
        git fetch origin || true
        
        # Verificar en qué rama estamos
        CURRENT_BRANCH=\$(git branch --show-current 2>/dev/null || echo "")
        echo "  → Rama actual: \${CURRENT_BRANCH:-'no detectada'}"
        
        # Resetear cualquier cambio local para asegurar que tenemos la versión más reciente
        echo "  → Descartando cambios locales (si hay)..."
        git reset --hard HEAD 2>/dev/null || true
        git clean -fd 2>/dev/null || true
        
        # Intentar pull de master primero, luego main, luego la rama actual
        echo "  → Actualizando código..."
        if git pull origin master 2>/dev/null; then
            echo "  ✅ Repositorio actualizado desde master"
        elif git pull origin main 2>/dev/null; then
            echo "  ✅ Repositorio actualizado desde main"
        elif [ -n "\$CURRENT_BRANCH" ] && git pull origin "\$CURRENT_BRANCH" 2>/dev/null; then
            echo "  ✅ Repositorio actualizado desde \$CURRENT_BRANCH"
        elif git pull 2>/dev/null; then
            echo "  ✅ Repositorio actualizado"
        else
            echo "  ⚠️  No se pudo hacer pull automático, forzando actualización..."
            # Forzar actualización desde origin/master o origin/main
            if git fetch origin master 2>/dev/null && git reset --hard origin/master 2>/dev/null; then
                echo "  ✅ Repositorio actualizado forzadamente desde origin/master"
            elif git fetch origin main 2>/dev/null && git reset --hard origin/main 2>/dev/null; then
                echo "  ✅ Repositorio actualizado forzadamente desde origin/main"
            else
                echo "  ⚠️  No se pudo actualizar, pero continuando con código existente..."
            fi
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
    
    # Verificar que el directorio del backend existe
    if [ ! -d "\$REPO_NAME/shopping_exercise_backend" ]; then
        echo "  ❌ ERROR: Directorio shopping_exercise_backend no encontrado en \$REPO_NAME"
        echo "  💡 Contenido de \$REPO_NAME:"
        ls -la "\$REPO_NAME" 2>/dev/null || echo "  (Directorio no existe)"
        exit 1
    fi
    
    echo "  ✅ Repositorio listo"
    echo "  📁 Ubicación: /home/ec2-user/\$REPO_NAME/shopping_exercise_backend"
ENDSSH

echo "  ✅ Repositorio listo"
echo "  📝 Historial actualizado en: $HISTORY_FILE"
echo ""

# ============================================================================
# PASO 7: Levantar contenedores Docker
# ============================================================================

echo "🐳 Paso 7: Levantando contenedores Docker..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    BACKEND_DIR="/home/ec2-user/\${REPO_NAME}/shopping_exercise_backend"
    
    echo "  → Navegando a directorio del backend..."
    echo "  → Buscando en: /home/ec2-user/\$REPO_NAME"
    
    # Verificar que el directorio existe
    if [ ! -d "/home/ec2-user/\$REPO_NAME" ]; then
        echo "  ❌ ERROR: Directorio del repositorio no encontrado: /home/ec2-user/\$REPO_NAME"
        echo "  💡 Directorios disponibles en /home/ec2-user:"
        ls -la /home/ec2-user/ | head -10
        exit 1
    fi
    
    if [ ! -d "/home/ec2-user/\$REPO_NAME/shopping_exercise_backend" ]; then
        echo "  ❌ ERROR: Directorio shopping_exercise_backend no encontrado"
        echo "  💡 Contenido de /home/ec2-user/\$REPO_NAME:"
        ls -la "/home/ec2-user/\$REPO_NAME" | head -10
        exit 1
    fi
    
    cd "/home/ec2-user/\$REPO_NAME/shopping_exercise_backend"
    echo "  ✅ Directorio actual: \$(pwd)"
    
    echo "  → Verificando docker-compose.yml..."
    if [ ! -f "docker-compose.yml" ]; then
        echo "  ❌ ERROR: docker-compose.yml no encontrado"
        exit 1
    fi
    echo "  ✅ docker-compose.yml encontrado"
    
    echo "  → Verificando que Docker esté corriendo..."
    if ! sudo systemctl is-active --quiet docker; then
        echo "  → Iniciando Docker..."
        sudo systemctl start docker
        sleep 2
    fi
    echo "  ✅ Docker está corriendo"
    
    # Verificar si los contenedores ya están corriendo
    RUNNING_CONTAINERS=$(sudo docker ps --filter "name=shopping_" --format "{{.Names}}" 2>/dev/null | wc -l)
    # Asegurar que sea un número válido
    if [ -z "$RUNNING_CONTAINERS" ] || [ "$RUNNING_CONTAINERS" = "" ]; then
        RUNNING_CONTAINERS=0
    fi
    if [ "$RUNNING_CONTAINERS" -gt 0 ] 2>/dev/null; then
        echo "  → Contenedores ya están corriendo, verificando estado..."
        sudo docker ps --filter "name=shopping_"
        
        # Verificar que PostgreSQL esté corriendo
        if ! sudo docker ps --format "{{.Names}}" | grep -q "^shopping_postgres$"; then
            echo "  ⚠️  PostgreSQL no está corriendo, iniciándolo..."
            if sudo docker ps -a --format "{{.Names}}" | grep -q "^shopping_postgres$"; then
                echo "  → Iniciando contenedor PostgreSQL existente..."
                sudo docker start shopping_postgres 2>/dev/null || {
                    echo "  ⚠️  No se pudo iniciar PostgreSQL existente, creando nuevo..."
                    # Crear red si no existe
                    sudo docker network create shopping_network 2>/dev/null || true
                    # Crear nuevo contenedor PostgreSQL (sin montar init.sql, lo ejecutaremos después)
                    echo "  → Creando nuevo contenedor PostgreSQL..."
                    sudo docker run -d \
                        --name shopping_postgres \
                        --network shopping_network \
                        -e POSTGRES_PASSWORD=postgres123 \
                        -e POSTGRES_DB=shopping_db \
                        -e POSTGRES_USER=postgres \
                        postgres:15-alpine || {
                        echo "  ❌ ERROR: No se pudo crear contenedor PostgreSQL"
                        exit 1
                    }
                    echo "  ✅ Contenedor PostgreSQL creado (init.sql se ejecutará después si es necesario)"
                }
                sleep 5  # Esperar a que PostgreSQL esté listo
            else
                echo "  ⚠️  Contenedor PostgreSQL no existe, creándolo..."
                # Crear red si no existe
                sudo docker network create shopping_network 2>/dev/null || true
                
                # Verificar si existe init.sql
                BACKEND_DIR="\$(pwd)"
                INIT_SQL_FILE="\${BACKEND_DIR}/database/init.sql"
                
                if [ -f "\$INIT_SQL_FILE" ] && [ ! -d "\$INIT_SQL_FILE" ]; then
                    echo "  → Encontrado init.sql, montándolo en el contenedor"
                    echo "  → Ruta: \$INIT_SQL_FILE"
                    sudo docker run -d \
                        --name shopping_postgres \
                        --network shopping_network \
                        -e POSTGRES_PASSWORD=postgres123 \
                        -e POSTGRES_DB=shopping_db \
                        -e POSTGRES_USER=postgres \
                        -v "\$INIT_SQL_FILE:/docker-entrypoint-initdb.d/init.sql:ro" \
                        postgres:15-alpine || {
                        echo "  ❌ ERROR: No se pudo crear contenedor PostgreSQL"
                        exit 1
                    }
                else
                    echo "  ⚠️  No se encontró database/init.sql, creando contenedor sin él"
                    sudo docker run -d \
                        --name shopping_postgres \
                        --network shopping_network \
                        -e POSTGRES_PASSWORD=postgres123 \
                        -e POSTGRES_DB=shopping_db \
                        -e POSTGRES_USER=postgres \
                        postgres:15-alpine || {
                        echo "  ❌ ERROR: No se pudo crear contenedor PostgreSQL"
                        exit 1
                    }
                fi
                sleep 5
            fi
        else
            echo "  ✅ PostgreSQL está corriendo"
        fi
        
        # Verificar si el contenedor API tiene DB_SSL configurado y código actualizado
        echo "  → Verificando configuración del contenedor API..."
        NEEDS_REBUILD=false
        
        if sudo docker inspect shopping_api 2>/dev/null | grep -q '"DB_SSL"'; then
            DB_SSL_VALUE=$(sudo docker inspect shopping_api 2>/dev/null | grep -A 1 '"DB_SSL"' | grep '"Value"' | cut -d'"' -f4 || echo "")
            if [ "$DB_SSL_VALUE" != "false" ]; then
                echo "  ⚠️  Contenedor API tiene DB_SSL=$DB_SSL_VALUE (debería ser false)"
                NEEDS_REBUILD=true
            fi
        else
            echo "  ⚠️  Contenedor API no tiene DB_SSL configurado"
            NEEDS_REBUILD=true
        fi
        
        # Verificar si el código de database.js está actualizado (contiene DB_SSL check)
        if sudo docker exec shopping_api grep -q "process.env.DB_SSL === 'true'" /app/src/config/database.js 2>/dev/null; then
            echo "  ✅ Código de database.js está actualizado"
        else
            echo "  ⚠️  Código de database.js puede no estar actualizado"
            NEEDS_REBUILD=true
        fi
        
        if [ "$NEEDS_REBUILD" = true ]; then
            echo "  → Reconstruyendo contenedor API para aplicar configuración correcta..."
            # Detener y eliminar solo el API, no PostgreSQL
            sudo docker stop shopping_api 2>/dev/null || true
            sudo docker rm shopping_api 2>/dev/null || true
            
            # Reconstruir la imagen
            if [ -f "api/Dockerfile" ]; then
                echo "  → Reconstruyendo imagen del API..."
                sudo docker build -t shopping_exercise_backend-api:latest -f api/Dockerfile api/ || {
                    echo "  ❌ ERROR: Falló la reconstrucción del API"
                    exit 1
                }
            fi
            
            # Crear nuevo contenedor API con configuración correcta
            echo "  → Creando nuevo contenedor API con configuración correcta..."
            sudo docker run -d \
                --name shopping_api \
                --network shopping_network \
                -p 3000:3000 \
                -e NODE_ENV=production \
                -e PORT=3000 \
                -e DATABASE_URL=postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db \
                -e DB_SSL=false \
                -e JWT_SECRET=f3c9e8b1a47d2e9c5f0a3d7b9e6c1f4a8d2b7c9e1f0a4b3c7d9e2f1a6c8b0d3 \
                -e JWT_EXPIRES_IN=1d \
                shopping_exercise_backend-api:latest || {
                echo "  ❌ ERROR: No se pudo crear contenedor API"
                exit 1
            }
            echo "  ✅ Contenedor API reconstruido y reiniciado"
            sleep 3  # Esperar a que el API inicie
        else
            echo "  ✅ Contenedor API tiene configuración correcta"
        fi
        
        # Verificar e iniciar Adminer si no está corriendo
        if ! sudo docker ps --format "{{.Names}}" | grep -q "^shopping_adminer$"; then
            echo "  ⚠️  Adminer no está corriendo, iniciándolo..."
            if sudo docker ps -a --format "{{.Names}}" | grep -q "^shopping_adminer$"; then
                echo "  → Iniciando contenedor Adminer existente..."
                sudo docker start shopping_adminer 2>/dev/null || {
                    echo "  ⚠️  No se pudo iniciar Adminer existente, creando nuevo..."
                    sudo docker rm shopping_adminer 2>/dev/null || true
                    # Crear red si no existe
                    sudo docker network create shopping_network 2>/dev/null || true
                    sudo docker run -d \
                        --name shopping_adminer \
                        --network shopping_network \
                        -p 8080:8080 \
                        adminer:latest || {
                        echo "  ❌ ERROR: No se pudo crear contenedor Adminer"
                    }
                }
            else
                echo "  → Creando contenedor Adminer..."
                # Crear red si no existe
                sudo docker network create shopping_network 2>/dev/null || true
                sudo docker run -d \
                    --name shopping_adminer \
                    --network shopping_network \
                    -p 8080:8080 \
                    adminer:latest || {
                    echo "  ❌ ERROR: No se pudo crear contenedor Adminer"
                }
            fi
        else
            echo "  ✅ Adminer está corriendo"
        fi
    else
        echo "  → No hay contenedores corriendo, iniciando..."
        
        echo "  → Deteniendo y eliminando contenedores existentes (si hay)..."
        sudo docker-compose down 2>/dev/null || sudo docker compose down 2>/dev/null || true
        # También eliminar contenedores manualmente si existen
        sudo docker stop shopping_api shopping_postgres shopping_adminer 2>/dev/null || true
        sudo docker rm shopping_api shopping_postgres shopping_adminer 2>/dev/null || true
        
        echo "  → Construyendo imágenes Docker..."
        # Verificar que docker-compose funcione antes de usarlo
        DOCKER_COMPOSE_WORKS=false
        if docker compose version &> /dev/null 2>&1; then
            DOCKER_COMPOSE_WORKS=true
            DOCKER_COMPOSE_CMD="docker compose"
        elif docker-compose version &> /dev/null 2>&1; then
            DOCKER_COMPOSE_WORKS=true
            DOCKER_COMPOSE_CMD="docker-compose"
        fi
        
        if [ "$DOCKER_COMPOSE_WORKS" = true ]; then
            echo "  → Usando $DOCKER_COMPOSE_CMD para construir..."
            if sudo $DOCKER_COMPOSE_CMD build 2>&1; then
                echo "  ✅ Imágenes construidas correctamente"
            else
                echo "  ⚠️  $DOCKER_COMPOSE_CMD build falló, intentando con docker build directo..."
                # Construir manualmente cada servicio usando docker build
                if [ -f "api/Dockerfile" ]; then
                    echo "  → Construyendo imagen del API..."
                    sudo docker build -t shopping_exercise_backend-api:latest -f api/Dockerfile api/ || {
                        echo "  ❌ ERROR: Falló la construcción del API"
                        exit 1
                    }
                fi
                echo "  ✅ Imágenes construidas (método directo)"
            fi
        else
            echo "  ⚠️  docker-compose no funciona, usando docker build directo..."
            # Construir manualmente cada servicio usando docker build
            if [ -f "api/Dockerfile" ]; then
                echo "  → Construyendo imagen del API..."
                sudo docker build -t shopping_exercise_backend-api:latest -f api/Dockerfile api/ || {
                    echo "  ❌ ERROR: Falló la construcción del API"
                    exit 1
                }
            fi
            echo "  ✅ Imágenes construidas (método directo)"
        fi
        
        echo "  → Configurando variables de entorno para producción..."
        # Asegurar que DB_SSL esté configurado en docker-compose.yml
        if grep -q "DB_SSL" docker-compose.yml 2>/dev/null; then
            echo "  ✅ DB_SSL ya está configurado en docker-compose.yml"
        else
            echo "  → Agregando DB_SSL=false a docker-compose.yml..."
            # Agregar DB_SSL después de DATABASE_URL
            sudo sed -i '/DATABASE_URL:/a\      DB_SSL: '\''false'\''' docker-compose.yml || {
                echo "  ⚠️  No se pudo actualizar docker-compose.yml automáticamente"
                echo "  💡 Asegúrate de que DB_SSL=false esté en las variables de entorno del servicio api"
            }
        fi
        
        # Actualizar NODE_ENV a production si está en development
        sudo sed -i "s/NODE_ENV: development/NODE_ENV: production/" docker-compose.yml 2>/dev/null || true
        
        echo "  → Iniciando contenedores (reconstruyendo si es necesario)..."
        # Verificar que docker-compose funcione antes de usarlo
        if docker compose version &> /dev/null 2>&1; then
            if sudo docker compose up -d --build 2>&1; then
                echo "  ✅ Contenedores iniciados y reconstruidos"
            else
                echo "  ❌ ERROR: Falló al iniciar contenedores"
                echo "  💡 Revisa los logs con: sudo docker compose logs"
                exit 1
            fi
        elif docker-compose version &> /dev/null 2>&1; then
            if sudo docker-compose up -d --build 2>&1; then
                echo "  ✅ Contenedores iniciados y reconstruidos"
            else
                echo "  ❌ ERROR: Falló al iniciar contenedores"
                echo "  💡 Revisa los logs con: sudo docker-compose logs"
                exit 1
            fi
        else
            echo "  ⚠️  docker-compose no funciona, iniciando contenedores manualmente..."
            
            # Crear red si no existe
            sudo docker network create shopping_network 2>/dev/null || true
            
            # Iniciar PostgreSQL
            if sudo docker ps -a --format "{{.Names}}" | grep -q "^shopping_postgres$"; then
                echo "  → Iniciando contenedor PostgreSQL existente..."
                sudo docker start shopping_postgres 2>/dev/null || true
            else
                echo "  → Creando contenedor PostgreSQL..."
                # Crear contenedor sin montar init.sql (lo ejecutaremos después)
                # Esto evita problemas con el montaje del volumen
                sudo docker run -d \
                    --name shopping_postgres \
                    --network shopping_network \
                    -e POSTGRES_PASSWORD=postgres123 \
                    -e POSTGRES_DB=shopping_db \
                    -e POSTGRES_USER=postgres \
                    postgres:15-alpine || {
                    echo "  ❌ ERROR: No se pudo crear contenedor PostgreSQL"
                    exit 1
                }
                echo "  ✅ Contenedor PostgreSQL creado (init.sql se ejecutará después si es necesario)"
            fi
            
            # Esperar a que PostgreSQL esté listo
            echo "  → Esperando a que PostgreSQL esté listo..."
            sleep 5
            
            # Iniciar API
            if sudo docker ps -a --format "{{.Names}}" | grep -q "^shopping_api$"; then
                echo "  → Iniciando contenedor API existente..."
                sudo docker start shopping_api 2>/dev/null || true
            else
                echo "  → Creando contenedor API..."
                # Usar docker-compose.prod.yml si existe, sino usar docker-compose.yml
                if [ -f "docker-compose.prod.yml" ]; then
                    echo "  → Usando docker-compose.prod.yml..."
                    # Intentar usar docker-compose.prod.yml
                    if docker compose version &> /dev/null 2>&1; then
                        sudo docker compose -f docker-compose.prod.yml up -d api 2>&1 || {
                            echo "  ⚠️  No se pudo usar docker-compose.prod.yml, creando manualmente..."
                            sudo docker run -d \
                                --name shopping_api \
                                --network shopping_network \
                                -p 3000:3000 \
                                -e NODE_ENV=production \
                        -e PORT=3000 \
                        -e DATABASE_URL=postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db \
                        -e DB_SSL=false \
                        -e JWT_SECRET=f3c9e8b1a47d2e9c5f0a3d7b9e6c1f4a8d2b7c9e1f0a4b3c7d9e2f1a6c8b0d3 \
                        -e JWT_EXPIRES_IN=1d \
                        shopping_exercise_backend-api:latest || {
                        echo "  ❌ ERROR: No se pudo crear contenedor API"
                        exit 1
                    }
                        }
                    else
                        echo "  → Creando contenedor API manualmente..."
                        sudo docker run -d \
                            --name shopping_api \
                            --network shopping_network \
                            -p 3000:3000 \
                            -e NODE_ENV=production \
                            -e PORT=3000 \
                            -e DATABASE_URL=postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db \
                            -e DB_SSL=false \
                            -e JWT_SECRET=f3c9e8b1a47d2e9c5f0a3d7b9e6c1f4a8d2b7c9e1f0a4b3c7d9e2f1a6c8b0d3 \
                            -e JWT_EXPIRES_IN=1d \
                            shopping_exercise_backend-api:latest || {
                            echo "  ❌ ERROR: No se pudo crear contenedor API"
                            exit 1
                        }
                    fi
                else
                    echo "  → Creando contenedor API manualmente..."
                    sudo docker run -d \
                        --name shopping_api \
                        --network shopping_network \
                        -p 3000:3000 \
                        -e NODE_ENV=production \
                        -e PORT=3000 \
                        -e DATABASE_URL=postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db \
                        -e DB_SSL=false \
                        -e JWT_SECRET=f3c9e8b1a47d2e9c5f0a3d7b9e6c1f4a8d2b7c9e1f0a4b3c7d9e2f1a6c8b0d3 \
                        -e JWT_EXPIRES_IN=1d \
                        shopping_exercise_backend-api:latest || {
                        echo "  ❌ ERROR: No se pudo crear contenedor API"
                        exit 1
                    }
                fi
            fi
            
            # Verificar e iniciar Adminer
            if sudo docker ps --format "{{.Names}}" | grep -q "^shopping_adminer$"; then
                echo "  ✅ Adminer ya está corriendo"
            elif sudo docker ps -a --format "{{.Names}}" | grep -q "^shopping_adminer$"; then
                echo "  → Iniciando contenedor Adminer existente..."
                sudo docker start shopping_adminer 2>/dev/null || {
                    echo "  ⚠️  No se pudo iniciar Adminer existente, creando nuevo..."
                    sudo docker rm shopping_adminer 2>/dev/null || true
                    sudo docker run -d \
                        --name shopping_adminer \
                        --network shopping_network \
                        -p 8080:8080 \
                        adminer:latest || {
                        echo "  ❌ ERROR: No se pudo crear contenedor Adminer"
                        exit 1
                    }
                }
            else
                echo "  → Creando contenedor Adminer..."
                sudo docker run -d \
                    --name shopping_adminer \
                    --network shopping_network \
                    -p 8080:8080 \
                    adminer:latest || {
                    echo "  ❌ ERROR: No se pudo crear contenedor Adminer"
                    exit 1
                }
            fi
            
            echo "  ✅ Contenedores iniciados manualmente"
        fi
    fi
    
    echo "  → Esperando a que los contenedores estén listos..."
    sleep 10
    
    echo "  → Verificando estado de contenedores..."
    echo "  --- Contenedores corriendo ---"
    sudo docker ps --filter "name=shopping_"
    echo ""
    echo "  --- Todos los contenedores (incluyendo detenidos) ---"
    sudo docker ps -a --filter "name=shopping_"
    
    echo ""
    echo "  → Verificando logs de los contenedores..."
    echo "  --- Logs del API (últimas 30 líneas) ---"
    if sudo docker ps --format "{{.Names}}" | grep -q "shopping_api"; then
        sudo docker logs shopping_api --tail 30 2>&1 || echo "  (No se pudieron obtener logs)"
    else
        echo "  ⚠️  Contenedor shopping_api no está corriendo"
    fi
    echo ""
    echo "  --- Logs de PostgreSQL (últimas 15 líneas) ---"
    if sudo docker ps --format "{{.Names}}" | grep -q "shopping_postgres"; then
        sudo docker logs shopping_postgres --tail 15 2>&1 || echo "  (No se pudieron obtener logs)"
    else
        echo "  ⚠️  Contenedor shopping_postgres no está corriendo"
    fi
    
    echo ""
    echo "  → Verificando si la base de datos necesita inicialización..."
    # Esperar un poco más para que PostgreSQL esté completamente listo
    sleep 3
    
    # Verificar si PostgreSQL está corriendo
    if ! sudo docker ps --format "{{.Names}}" | grep -q "^shopping_postgres$"; then
        echo "  ⚠️  PostgreSQL no está corriendo, no se puede verificar la base de datos"
        echo "  💡 Inicia PostgreSQL primero: sudo docker start shopping_postgres"
    elif sudo docker exec shopping_postgres psql -U postgres -d shopping_db -c "\dt" 2>&1 | grep -q "users"; then
        echo "  ✅ La base de datos tiene tablas (ya está inicializada)"
        # Verificar si hay datos
        USER_COUNT=$(sudo docker exec shopping_postgres psql -U postgres -d shopping_db -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' ' || echo "0")
        if [ "$USER_COUNT" = "0" ] || [ -z "$USER_COUNT" ]; then
            echo "  ⚠️  La base de datos está vacía (sin usuarios)"
            echo "  → Creando usuarios del sistema..."
            
            # Crear usuario público
            if [ -f "api/add_public_user.js" ]; then
                if sudo docker exec -e DATABASE_URL="postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db" shopping_api node add_public_user.js 2>&1; then
                    echo "  ✅ Usuario público creado correctamente"
                else
                    echo "  ⚠️  No se pudo crear el usuario público automáticamente"
                fi
            fi
            
            # Crear usuario de prueba
            if [ -f "api/add_test_user.js" ]; then
                sleep 1
                if sudo docker exec -e DATABASE_URL="postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db" shopping_api node add_test_user.js 2>&1; then
                    echo "  ✅ Usuario de prueba creado correctamente"
                else
                    echo "  ⚠️  No se pudo crear el usuario de prueba automáticamente"
                fi
            fi
        else
            echo "  ✅ La base de datos tiene $USER_COUNT usuario(s)"
        fi
    else
        echo "  ⚠️  La base de datos parece estar vacía (sin tablas)"
        echo "  → Intentando ejecutar init.sql..."
        
        if [ -f "database/init.sql" ]; then
            echo "  → Ejecutando init.sql..."
            if sudo docker exec -i shopping_postgres psql -U postgres -d shopping_db < database/init.sql 2>&1; then
                echo "  ✅ init.sql ejecutado correctamente"
                echo "  → Verificando tablas creadas..."
                sudo docker exec shopping_postgres psql -U postgres -d shopping_db -c "\dt" 2>&1 | head -20
                
                # Crear usuario público después de inicializar
                echo "  → Creando usuario público..."
                if [ -f "api/add_public_user.js" ]; then
                    sleep 2  # Esperar un poco para que las tablas estén listas
                    # Usar DATABASE_URL con el nombre correcto del contenedor
                    if sudo docker exec -e DATABASE_URL="postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db" shopping_api node add_public_user.js 2>&1; then
                        echo "  ✅ Usuario público creado correctamente"
                    else
                        echo "  ⚠️  No se pudo crear el usuario público automáticamente"
                        echo "  💡 Puedes ejecutarlo manualmente:"
                        echo "     sudo docker exec -e DATABASE_URL='postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db' shopping_api node add_public_user.js"
                    fi
                fi
            else
                echo "  ⚠️  ADVERTENCIA: No se pudo ejecutar init.sql automáticamente"
                echo "  💡 Puedes ejecutarlo manualmente:"
                echo "     sudo docker exec -i shopping_postgres psql -U postgres -d shopping_db < database/init.sql"
            fi
        else
            echo "  ❌ ERROR: No se encontró database/init.sql"
            echo "  💡 La base de datos necesita ser inicializada manualmente"
        fi
    fi
    
    # Crear usuarios si no existen (después de verificar/crear tablas)
    echo ""
    echo "  → Verificando usuarios del sistema..."
    
    # Verificar y crear usuario público
    echo "  → Verificando si existe el usuario público..."
    USER_PUBLIC_COUNT=$(sudo docker exec shopping_postgres psql -U postgres -d shopping_db -t -c "SELECT COUNT(*) FROM users WHERE email = 'user@ejemplo.com';" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$USER_PUBLIC_COUNT" = "0" ] || [ -z "$USER_PUBLIC_COUNT" ]; then
        echo "  ⚠️  El usuario público no existe"
        echo "  → Creando usuario público..."
        if [ -f "api/add_public_user.js" ]; then
            sleep 2  # Esperar un poco para que las tablas estén listas
            # Usar DATABASE_URL con el nombre correcto del contenedor
            if sudo docker exec -e DATABASE_URL="postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db" shopping_api node add_public_user.js 2>&1; then
                echo "  ✅ Usuario público creado correctamente"
            else
                echo "  ⚠️  No se pudo crear el usuario público automáticamente"
                echo "  💡 Puedes ejecutarlo manualmente:"
                echo "     sudo docker exec -e DATABASE_URL='postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db' shopping_api node add_public_user.js"
            fi
        else
            echo "  ⚠️  No se encontró api/add_public_user.js"
        fi
    else
        echo "  ✅ El usuario público ya existe"
    fi
    
    # Verificar y crear usuario de prueba
    echo "  → Verificando si existe el usuario de prueba..."
    USER_TEST_COUNT=$(sudo docker exec shopping_postgres psql -U postgres -d shopping_db -t -c "SELECT COUNT(*) FROM users WHERE email = 'test@ejemplo.com';" 2>/dev/null | tr -d ' ' || echo "0")
    if [ "$USER_TEST_COUNT" = "0" ] || [ -z "$USER_TEST_COUNT" ]; then
        echo "  ⚠️  El usuario de prueba no existe"
        echo "  → Creando usuario de prueba..."
        if [ -f "api/add_test_user.js" ]; then
            sleep 2  # Esperar un poco para que las tablas estén listas
            # Usar DATABASE_URL con el nombre correcto del contenedor
            if sudo docker exec -e DATABASE_URL="postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db" shopping_api node add_test_user.js 2>&1; then
                echo "  ✅ Usuario de prueba creado correctamente"
            else
                echo "  ⚠️  No se pudo crear el usuario de prueba automáticamente"
                echo "  💡 Puedes ejecutarlo manualmente:"
                echo "     sudo docker exec -e DATABASE_URL='postgresql://postgres:postgres123@shopping_postgres:5432/shopping_db' shopping_api node add_test_user.js"
            fi
        else
            echo "  ⚠️  No se encontró api/add_test_user.js"
        fi
    else
        echo "  ✅ El usuario de prueba ya existe"
    fi
    
    
    echo ""
    echo "  ✅ Verificación completada"
ENDSSH

echo "  ✅ Contenedores levantados"
echo "  📝 Historial actualizado en: $HISTORY_FILE"
echo ""

# ============================================================================
# PASO 8: Configurar nginx como reverse proxy
# ============================================================================

echo "🌐 Paso 8: Configurando nginx como reverse proxy..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ec2-user@${PUBLIC_IP} << ENDSSH | tee -a "$HISTORY_FILE"
    set -e
    
    REPO_NAME="$REPO_NAME"
    
    echo "  → Configurando nginx como reverse proxy para el backend..."
    
    # Asegurar que nginx esté instalado
    if ! command -v nginx &> /dev/null; then
        echo "  → Instalando nginx..."
        sudo dnf install -y -q nginx
    fi
    
    # Crear directorio de configuración si no existe
    sudo mkdir -p /etc/nginx/conf.d
    
    # Limpiar otras configuraciones que puedan causar conflicto
    echo "  → Limpiando configuraciones antiguas de nginx..."
    sudo rm -f /etc/nginx/conf.d/default.conf 2>/dev/null || true
    sudo rm -f /etc/nginx/conf.d/flutter-app.conf 2>/dev/null || true
    sudo rm -f /etc/nginx/conf.d/flutter-portal.conf 2>/dev/null || true
    
    # Crear configuración base de nginx (se actualizará cuando se desplieguen las apps Flutter)
    sudo tee /etc/nginx/conf.d/shopping-app.conf > /dev/null << 'NGINXCONF'
server {
    listen 80;
    server_name _;
    
    # Health check directo (sin /api)
    location = /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
    
    # Backend API en /api
    location /api {
        # El backend espera rutas con /api, así que mantenemos el path completo
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
    
    # Redirigir raíz a /api por ahora (se actualizará cuando haya apps Flutter)
    location = / {
        return 301 /api;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
}
NGINXCONF
    
    echo "  → Probando configuración de nginx..."
    if sudo nginx -t 2>&1; then
        echo "  ✅ Configuración de nginx válida"
    else
        echo "  ⚠️  Error en configuración de nginx"
        echo "  💡 Revisa la configuración con: sudo nginx -t"
    fi
    
    echo "  → Iniciando/reiniciando nginx..."
    sudo systemctl restart nginx 2>/dev/null || sudo systemctl start nginx || {
        echo "  ⚠️  No se pudo iniciar nginx, intentando habilitarlo..."
        sudo systemctl enable nginx
        sudo systemctl start nginx
    }
    
    # Verificar que nginx esté corriendo
    sleep 2
    if sudo systemctl is-active --quiet nginx; then
        echo "  ✅ nginx configurado y corriendo"
        
        # Verificar que Adminer esté accesible directamente
        echo "  → Verificando que Adminer esté accesible..."
        if curl -s -f -m 5 http://localhost:8080 >/dev/null 2>&1; then
            echo "  ✅ Adminer responde en localhost:8080"
        else
            echo "  ⚠️  ADVERTENCIA: Adminer no responde en localhost:8080"
            echo "  💡 Verifica que el contenedor esté corriendo:"
            echo "     sudo docker ps | grep adminer"
            echo "     sudo docker logs shopping_adminer --tail 20"
        fi
        
        # Verificar que el proxy de Adminer funcione
        echo "  → Verificando que el proxy de Adminer funcione..."
        if curl -s -f -m 5 http://localhost/adminer/ >/dev/null 2>&1; then
            echo "  ✅ Proxy de Adminer funciona correctamente"
        else
            echo "  ⚠️  ADVERTENCIA: Proxy de Adminer no responde"
            echo "  💡 Verifica la configuración de nginx:"
            echo "     sudo tail -20 /var/log/nginx/error.log"
        fi
    else
        echo "  ⚠️  nginx puede no estar corriendo"
        echo "  💡 Verifica con: sudo systemctl status nginx"
        echo "  💡 Revisa logs con: sudo tail -f /var/log/nginx/error.log"
    fi
ENDSSH

echo "  ✅ nginx configurado"
echo "  📝 Historial completo guardado en: $HISTORY_FILE"
echo ""

# ============================================================================
# RESUMEN
# ============================================================================

echo "=========================================="
echo "✅ Deployment del Backend completado!"
echo ""
echo "📍 Información de la instancia:"
echo "   Instance ID: $INSTANCE_ID"
echo "   IP Pública: $PUBLIC_IP"
echo "   Usuario SSH: ec2-user"
echo "   Key File: $KEY_FILE"
echo ""
echo "🔐 Para conectarte por SSH:"
echo "   ssh -i $KEY_FILE ec2-user@${PUBLIC_IP}"
echo ""
echo "📝 Para ver el historial de comandos ejecutados:"
echo "   cat $HISTORY_FILE"
echo "   o"
echo "   less $HISTORY_FILE"
echo ""
echo "🐳 Para ver los contenedores:"
echo "   ssh -i $KEY_FILE ec2-user@${PUBLIC_IP}"
echo "   cd $REPO_NAME/shopping_exercise_backend"
echo "   sudo docker ps"
echo "   sudo docker-compose ps"
echo ""
echo "🌐 🌐 🌐 TU BACKEND API ESTÁ DISPONIBLE EN: 🌐 🌐 🌐"
echo ""
echo "   👉 API: http://${PUBLIC_IP}/api 👈"
echo "   👉 Health: http://${PUBLIC_IP}/health 👈"
echo ""
echo "📝 Nota: El backend está detrás de nginx (reverse proxy)"
echo "   El puerto 3000 NO está expuesto públicamente (solo localhost)"
echo "   Las apps Flutter se agregarán en /app y /portal cuando las despliegues"
echo ""
echo "🔍 Para verificar el estado de Docker:"
echo "   ./scripts/ec2/check_docker_status.sh shopping-app"
echo "=========================================="

