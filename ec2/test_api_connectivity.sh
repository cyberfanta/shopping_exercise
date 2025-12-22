#!/bin/bash

###############################################################################
# SCRIPT DE PRUEBA DE CONECTIVIDAD DEL API
###############################################################################
# Ejecuta este script en el servidor EC2 para diagnosticar problemas de
# conectividad entre los frontends Flutter y el backend API
###############################################################################

echo "=========================================="
echo "🔍 PRUEBAS DE CONECTIVIDAD DEL API"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# 1. VERIFICAR CONTENEDORES
# ============================================================================
echo "1️⃣  Verificando contenedores Docker..."
echo "----------------------------------------"
if sudo docker ps | grep -q "shopping_api"; then
    echo -e "${GREEN}✅ Contenedor shopping_api está corriendo${NC}"
    sudo docker ps | grep shopping_api
else
    echo -e "${RED}❌ Contenedor shopping_api NO está corriendo${NC}"
fi
echo ""

if sudo docker ps | grep -q "shopping_postgres"; then
    echo -e "${GREEN}✅ Contenedor shopping_postgres está corriendo${NC}"
    sudo docker ps | grep shopping_postgres
else
    echo -e "${RED}❌ Contenedor shopping_postgres NO está corriendo${NC}"
fi
echo ""

# ============================================================================
# 2. VERIFICAR RED DOCKER
# ============================================================================
echo "2️⃣  Verificando red Docker..."
echo "----------------------------------------"
if sudo docker network ls | grep -q "shopping_network"; then
    echo -e "${GREEN}✅ Red shopping_network existe${NC}"
    echo "Contenedores en la red:"
    sudo docker network inspect shopping_network --format '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || echo "  (No se pudieron listar)"
else
    echo -e "${RED}❌ Red shopping_network NO existe${NC}"
fi
echo ""

# ============================================================================
# 3. PROBAR API DIRECTAMENTE (localhost:3000)
# ============================================================================
echo "3️⃣  Probando API directamente en localhost:3000..."
echo "----------------------------------------"

echo "→ Health check:"
HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost:3000/health 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | grep -v "HTTP_CODE")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health check exitoso (HTTP $HTTP_CODE)${NC}"
    echo "Respuesta: $RESPONSE_BODY"
else
    echo -e "${RED}❌ Health check falló (HTTP $HTTP_CODE)${NC}"
    echo "Respuesta: $RESPONSE_BODY"
fi
echo ""

echo "→ Probando endpoint /api/auth/login (POST):"
LOGIN_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST http://localhost:3000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@ejemplo.com","password":"Test123!"}' 2>&1)
LOGIN_HTTP_CODE=$(echo "$LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
LOGIN_BODY=$(echo "$LOGIN_RESPONSE" | grep -v "HTTP_CODE")

if [ "$LOGIN_HTTP_CODE" = "200" ] || [ "$LOGIN_HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✅ Login endpoint responde (HTTP $LOGIN_HTTP_CODE)${NC}"
    echo "Respuesta: $LOGIN_BODY"
else
    echo -e "${RED}❌ Login endpoint falló (HTTP $LOGIN_HTTP_CODE)${NC}"
    echo "Respuesta: $LOGIN_BODY"
fi
echo ""

# ============================================================================
# 4. PROBAR A TRAVÉS DE NGINX (/api)
# ============================================================================
echo "4️⃣  Probando API a través de nginx (/api)..."
echo "----------------------------------------"

echo "→ Verificando que nginx esté corriendo:"
if sudo systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ nginx está corriendo${NC}"
else
    echo -e "${RED}❌ nginx NO está corriendo${NC}"
fi
echo ""

echo "→ Health check a través de nginx (/api/health):"
NGINX_HEALTH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" http://localhost/api/health 2>&1)
NGINX_HEALTH_CODE=$(echo "$NGINX_HEALTH_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
NGINX_HEALTH_BODY=$(echo "$NGINX_HEALTH_RESPONSE" | grep -v "HTTP_CODE")

if [ "$NGINX_HEALTH_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Health check a través de nginx exitoso (HTTP $NGINX_HEALTH_CODE)${NC}"
    echo "Respuesta: $NGINX_HEALTH_BODY"
else
    echo -e "${RED}❌ Health check a través de nginx falló (HTTP $NGINX_HEALTH_CODE)${NC}"
    echo "Respuesta: $NGINX_HEALTH_BODY"
fi
echo ""

echo "→ Probando /api/auth/login a través de nginx:"
NGINX_LOGIN_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST http://localhost/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@ejemplo.com","password":"Test123!"}' 2>&1)
NGINX_LOGIN_CODE=$(echo "$NGINX_LOGIN_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
NGINX_LOGIN_BODY=$(echo "$NGINX_LOGIN_RESPONSE" | grep -v "HTTP_CODE")

if [ "$NGINX_LOGIN_CODE" = "200" ] || [ "$NGINX_LOGIN_CODE" = "401" ]; then
    echo -e "${GREEN}✅ Login a través de nginx responde (HTTP $NGINX_LOGIN_CODE)${NC}"
    echo "Respuesta: $NGINX_LOGIN_BODY"
else
    echo -e "${RED}❌ Login a través de nginx falló (HTTP $NGINX_LOGIN_CODE)${NC}"
    echo "Respuesta: $NGINX_LOGIN_BODY"
fi
echo ""

# ============================================================================
# 5. VERIFICAR LOGS DEL API
# ============================================================================
echo "5️⃣  Últimos logs del contenedor API (últimas 20 líneas)..."
echo "----------------------------------------"
sudo docker logs shopping_api --tail 20 2>&1 | tail -20
echo ""

# ============================================================================
# 6. VERIFICAR CONFIGURACIÓN DE NGINX
# ============================================================================
echo "6️⃣  Verificando configuración de nginx..."
echo "----------------------------------------"
echo "→ Configuración de /api:"
sudo grep -A 15 "location /api" /etc/nginx/conf.d/shopping-app.conf 2>/dev/null || echo "  (No se encontró la configuración)"
echo ""

echo "→ Verificando sintaxis de nginx:"
if sudo nginx -t 2>&1; then
    echo -e "${GREEN}✅ Configuración de nginx es válida${NC}"
else
    echo -e "${RED}❌ Configuración de nginx tiene errores${NC}"
fi
echo ""

# ============================================================================
# 7. VERIFICAR CONECTIVIDAD ENTRE CONTENEDORES
# ============================================================================
echo "7️⃣  Verificando conectividad entre contenedores..."
echo "----------------------------------------"
echo "→ Probando conexión desde API a PostgreSQL:"
if sudo docker exec shopping_api ping -c 2 shopping_postgres 2>/dev/null | grep -q "2 received"; then
    echo -e "${GREEN}✅ API puede comunicarse con PostgreSQL${NC}"
else
    echo -e "${YELLOW}⚠️  No se pudo verificar con ping, probando con psql...${NC}"
    if sudo docker exec shopping_postgres psql -U postgres -d shopping_db -c "SELECT 1;" 2>&1 | grep -q "1 row"; then
        echo -e "${GREEN}✅ PostgreSQL está funcionando${NC}"
    else
        echo -e "${RED}❌ PostgreSQL puede no estar funcionando correctamente${NC}"
    fi
fi
echo ""

# ============================================================================
# 8. VERIFICAR VARIABLES DE ENTORNO DEL API
# ============================================================================
echo "8️⃣  Verificando variables de entorno del API..."
echo "----------------------------------------"
echo "→ DATABASE_URL:"
sudo docker inspect shopping_api --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep DATABASE_URL || echo "  (No encontrado)"
echo ""

echo "→ DB_SSL:"
sudo docker inspect shopping_api --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep DB_SSL || echo "  (No encontrado - debería ser DB_SSL=false)"
echo ""

# ============================================================================
# RESUMEN
# ============================================================================
echo "=========================================="
echo "📋 RESUMEN"
echo "=========================================="
echo ""
echo "Para más información:"
echo "  - Logs del API: sudo docker logs shopping_api --tail 50"
echo "  - Logs de nginx: sudo tail -50 /var/log/nginx/error.log"
echo "  - Estado de contenedores: sudo docker ps"
echo "  - Configuración de nginx: sudo cat /etc/nginx/conf.d/shopping-app.conf"
echo ""

