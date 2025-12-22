#!/bin/bash

###############################################################################
# SCRIPT PARA CORREGIR EL CONTENEDOR DEL API
###############################################################################
# Este script reconstruye el contenedor del API con todas las variables de
# entorno correctas, incluyendo JWT_SECRET
###############################################################################

set -e

echo "=========================================="
echo "🔧 CORRIGIENDO CONTENEDOR DEL API"
echo "=========================================="
echo ""

cd "$(dirname "$0")/.." 2>/dev/null || cd ~/shopping_exercise || {
    echo "❌ ERROR: No se pudo encontrar el directorio del proyecto"
    exit 1
}

BACKEND_DIR="shopping_exercise_backend"

if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ ERROR: No se encontró el directorio $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

echo "📍 Directorio: $(pwd)"
echo ""

# Verificar que Docker esté corriendo
if ! sudo systemctl is-active --quiet docker; then
    echo "⚠️  Docker no está corriendo, iniciándolo..."
    sudo systemctl start docker
    sleep 2
fi

# Detener y eliminar el contenedor actual
echo "1️⃣  Deteniendo y eliminando contenedor API actual..."
sudo docker stop shopping_api 2>/dev/null || true
sudo docker rm shopping_api 2>/dev/null || true
echo "✅ Contenedor eliminado"
echo ""

# Verificar que la red existe
if ! sudo docker network ls | grep -q "shopping_network"; then
    echo "⚠️  Red shopping_network no existe, creándola..."
    sudo docker network create shopping_network
fi

# Reconstruir la imagen
echo "2️⃣  Reconstruyendo imagen del API..."
if [ -f "api/Dockerfile" ]; then
    sudo docker build -t shopping_exercise_backend-api:latest -f api/Dockerfile api/ || {
        echo "❌ ERROR: Falló la reconstrucción del API"
        exit 1
    }
    echo "✅ Imagen reconstruida"
else
    echo "❌ ERROR: No se encontró api/Dockerfile"
    exit 1
fi
echo ""

# Crear nuevo contenedor con todas las variables de entorno
echo "3️⃣  Creando nuevo contenedor API con configuración correcta..."
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
    echo "❌ ERROR: No se pudo crear contenedor API"
    exit 1
}

echo "✅ Contenedor creado"
echo ""

# Esperar a que el contenedor esté listo
echo "4️⃣  Esperando a que el API esté listo..."
sleep 5

# Verificar que el contenedor esté corriendo
if sudo docker ps | grep -q "shopping_api"; then
    echo "✅ Contenedor está corriendo"
else
    echo "❌ ERROR: El contenedor no está corriendo"
    echo "💡 Revisa los logs: sudo docker logs shopping_api"
    exit 1
fi
echo ""

# Verificar variables de entorno
echo "5️⃣  Verificando variables de entorno..."
echo "→ JWT_SECRET:"
if sudo docker inspect shopping_api --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep -q "JWT_SECRET"; then
    echo "  ✅ JWT_SECRET está configurado"
    sudo docker inspect shopping_api --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep JWT_SECRET
else
    echo "  ❌ JWT_SECRET NO está configurado"
fi
echo ""

# Probar el API
echo "6️⃣  Probando el API..."
MAX_RETRIES=5
RETRY_COUNT=0
API_RESPONDING=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s -f -m 5 http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ API responde correctamente"
        API_RESPONDING=true
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "⏳ Esperando API... (intento $RETRY_COUNT/$MAX_RETRIES)"
            sleep 3
        fi
    fi
done

if [ "$API_RESPONDING" = false ]; then
    echo "⚠️  El API aún no responde después de $MAX_RETRIES intentos"
    echo "💡 Revisa los logs: sudo docker logs shopping_api"
fi
echo ""

echo "=========================================="
echo "✅ CORRECCIÓN COMPLETADA"
echo "=========================================="
echo ""
echo "📝 Próximos pasos:"
echo "  1. Probar login: curl -X POST http://localhost/api/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"test@ejemplo.com\",\"password\":\"Test123!\"}'"
echo "  2. Ver logs: sudo docker logs shopping_api -f"
echo "  3. Reiniciar nginx si es necesario: sudo systemctl restart nginx"
echo ""

