#!/bin/bash

###############################################################################
# SCRIPT DE DEPLOYMENT - Landing Page en EC2 (Nginx raíz "/")
###############################################################################
#
# Este script:
# 1. Compila el landing page en React localmente
# 2. Lo despliega en la raíz "/" del nginx en EC2
# 3. Configura nginx para servir el landing page
#
###############################################################################

set -e

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

EC2_INSTANCE_NAME="shopping-app"  # Misma instancia que backend/app/portal
KEY_PAIR_NAME="aws-eb-shopping-exercise"
GITHUB_REPO_URL="git@github.com:cyberfanta/shopping_exercise.git"
ALLOWED_SSH_IP="38.74.224.33/32"

# URLs de las aplicaciones
APP_URL="http://100.49.43.143/app"
PORTAL_URL="http://100.49.43.143/portal"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LANDING_DIR="$PROJECT_ROOT/landing-page"

# ============================================================================
# PASO 0: Compilar Landing Page Localmente
# ============================================================================

echo "=========================================="
echo "🌐 DEPLOYMENT DE LANDING PAGE EN EC2"
echo "=========================================="
echo ""

echo "📦 Paso 0: Compilando landing page localmente..."
echo ""

# Crear directorio del landing page si no existe
mkdir -p "$LANDING_DIR"

cd "$LANDING_DIR"

# Verificar si Node.js está instalado
if ! command -v npm &> /dev/null; then
    echo "  ❌ ERROR: Node.js/npm no está instalado localmente"
    echo "  💡 Instala Node.js desde https://nodejs.org/"
    exit 1
fi

# Crear estructura del proyecto si no existe
if [ ! -f "package.json" ]; then
    echo "  → Creando estructura del proyecto React..."
    
    # Crear package.json
    cat > package.json << 'PKGEOF'
{
  "name": "shopping-landing-page",
  "version": "1.0.0",
  "description": "Landing page para Shopping Exercise",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
PKGEOF

    # Crear public/index.html
    mkdir -p public
    cat > public/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="Shopping Exercise - E-commerce Platform" />
    <title>Shopping Exercise</title>
  </head>
  <body>
    <noscript>Necesitas habilitar JavaScript para ejecutar esta aplicación.</noscript>
    <div id="root"></div>
  </body>
</html>
HTMLEOF

    # Crear src/index.js
    mkdir -p src
    cat > src/index.js << 'INDEXEOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
INDEXEOF

    # Crear src/index.css
    cat > src/index.css << 'CSSEOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',
    monospace;
}
CSSEOF

    echo "  ✅ Estructura del proyecto creada"
fi

# Crear src/App.js con las URLs actuales
echo "  → Actualizando App.js con URLs..."
cat > src/App.js << APPEOF
import React from 'react';
import './App.css';

function App() {
  const handleAppClick = () => {
    window.location.href = '${APP_URL}';
  };

  const handlePortalClick = () => {
    window.location.href = '${PORTAL_URL}';
  };

  return (
    <div className="App">
      <div className="container">
        <div className="content">
          <h1 className="title">🛒 Shopping Exercise</h1>
          <p className="subtitle">Plataforma de E-commerce</p>
          
          <div className="cards">
            <div className="card" onClick={handleAppClick}>
              <div className="card-icon">🛍️</div>
              <h2 className="card-title">App de Compras</h2>
              <p className="card-description">
                Explora nuestro catálogo de videos educativos y realiza tus compras de manera fácil y rápida.
              </p>
              <button className="btn btn-primary">Ir a la App</button>
            </div>
            
            <div className="card" onClick={handlePortalClick}>
              <div className="card-icon">⚙️</div>
              <h2 className="card-title">Portal Administrativo</h2>
              <p className="card-description">
                Gestiona productos, categorías, usuarios y órdenes desde el panel de administración.
              </p>
              <button className="btn btn-secondary">Ir al Portal</button>
            </div>
          </div>
          
          <div className="info">
            <p>Selecciona una opción para continuar</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
APPEOF

# Crear src/App.css mejorado
cat > src/App.css << 'CSSEOF'
.App {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.container {
  text-align: center;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 20px;
  padding: 60px 40px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  max-width: 1000px;
  width: 100%;
}

.content {
  display: flex;
  flex-direction: column;
  gap: 40px;
}

.title {
  font-size: 3.5rem;
  font-weight: bold;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 10px;
}

.subtitle {
  font-size: 1.5rem;
  color: #666;
  font-weight: 300;
  margin-bottom: 20px;
}

.cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 30px;
  margin-top: 30px;
}

.card {
  background: white;
  border-radius: 15px;
  padding: 40px 30px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
  cursor: pointer;
  border: 2px solid transparent;
}

.card:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 40px rgba(102, 126, 234, 0.2);
  border-color: #667eea;
}

.card-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

.card-title {
  font-size: 1.8rem;
  color: #333;
  margin-bottom: 15px;
  font-weight: 600;
}

.card-description {
  font-size: 1rem;
  color: #666;
  line-height: 1.6;
  margin-bottom: 25px;
}

.buttons {
  display: flex;
  gap: 20px;
  justify-content: center;
  flex-wrap: wrap;
  margin-top: 20px;
}

.btn {
  padding: 15px 40px;
  font-size: 1.1rem;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;
  text-decoration: none;
  display: inline-block;
  width: 100%;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(102, 126, 234, 0.4);
}

.btn-secondary {
  background: white;
  color: #667eea;
  border: 2px solid #667eea;
}

.btn-secondary:hover {
  background: #667eea;
  color: white;
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(102, 126, 234, 0.4);
}

.info {
  margin-top: 30px;
  color: #888;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .title {
    font-size: 2.5rem;
  }
  
  .subtitle {
    font-size: 1.2rem;
  }
  
  .cards {
    grid-template-columns: 1fr;
  }
  
  .container {
    padding: 40px 20px;
  }
  
  .card {
    padding: 30px 20px;
  }
}
CSSEOF

# Instalar dependencias si no existen
if [ ! -d "node_modules" ]; then
    echo "  → Instalando dependencias..."
    npm install --silent
fi

# Compilar
echo "  → Compilando para producción..."
npm run build

if [ ! -d "build" ]; then
    echo "  ❌ ERROR: La compilación falló - no se encontró el directorio build"
    exit 1
fi

echo "  ✅ Compilación completada"
echo ""

# ============================================================================
# PASO 1: Obtener información de la instancia EC2
# ============================================================================

echo "🔍 Paso 1: Obteniendo información de la instancia EC2..."
echo ""

# Buscar la instancia
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$EC2_INSTANCE_NAME" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "None" ]; then
    echo "  ❌ ERROR: No se encontró la instancia EC2 con nombre '$EC2_INSTANCE_NAME'"
    echo "  💡 Asegúrate de que la instancia esté corriendo y tenga el tag Name='$EC2_INSTANCE_NAME'"
    exit 1
fi

PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text 2>/dev/null || echo "")

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "  ❌ ERROR: No se pudo obtener la IP pública de la instancia"
    exit 1
fi

echo "  ✅ Instancia encontrada: $INSTANCE_ID"
echo "  ✅ IP Pública: $PUBLIC_IP"
echo ""

# ============================================================================
# PASO 2: Encontrar la clave SSH
# ============================================================================

echo "🔑 Paso 2: Localizando clave SSH..."
echo ""

SSH_KEY=""
if [ -f "$PROJECT_ROOT/$KEY_PAIR_NAME.pem" ]; then
    SSH_KEY="$PROJECT_ROOT/$KEY_PAIR_NAME.pem"
elif [ -f "$PROJECT_ROOT/$KEY_PAIR_NAME" ]; then
    SSH_KEY="$PROJECT_ROOT/$KEY_PAIR_NAME"
elif [ -f "$HOME/.ssh/$KEY_PAIR_NAME.pem" ]; then
    SSH_KEY="$HOME/.ssh/$KEY_PAIR_NAME.pem"
elif [ -f "$HOME/.ssh/$KEY_PAIR_NAME" ]; then
    SSH_KEY="$HOME/.ssh/$KEY_PAIR_NAME"
else
    echo "  ❌ ERROR: No se encontró la clave SSH '$KEY_PAIR_NAME'"
    echo "  💡 Buscando en:"
    echo "     - $PROJECT_ROOT/$KEY_PAIR_NAME.pem"
    echo "     - $HOME/.ssh/$KEY_PAIR_NAME.pem"
    exit 1
fi

chmod 400 "$SSH_KEY" 2>/dev/null || true
echo "  ✅ Clave SSH encontrada: $SSH_KEY"
echo ""

# Agregar clave al ssh-agent
if command -v ssh-add &> /dev/null; then
    ssh-add "$SSH_KEY" 2>/dev/null || true
fi

# ============================================================================
# PASO 3: Copiar archivos compilados a EC2
# ============================================================================

echo "📤 Paso 3: Copiando archivos compilados a EC2..."
echo ""

# Crear directorio temporal en EC2 y copiar archivos
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP << ENDSSH
    set -e
    echo "  → Creando directorio para landing page..."
    sudo mkdir -p /var/www/html/landing
    echo "  → Limpiando directorio anterior..."
    sudo rm -rf /var/www/html/landing/*
    echo "  ✅ Directorio listo"
ENDSSH

# Copiar archivos build
echo "  → Copiando archivos compilados..."
scp -i "$SSH_KEY" -r "$LANDING_DIR/build"/* ec2-user@$PUBLIC_IP:/tmp/landing-build/ || {
    echo "  → Creando directorio temporal en servidor..."
    ssh -i "$SSH_KEY" ec2-user@$PUBLIC_IP "mkdir -p /tmp/landing-build"
    scp -i "$SSH_KEY" -r "$LANDING_DIR/build"/* ec2-user@$PUBLIC_IP:/tmp/landing-build/
}

# Mover archivos al directorio de nginx
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP << ENDSSH
    set -e
    echo "  → Moviendo archivos a nginx..."
    sudo cp -r /tmp/landing-build/* /var/www/html/landing/
    sudo chown -R nginx:nginx /var/www/html/landing
    sudo chmod -R 755 /var/www/html/landing
    rm -rf /tmp/landing-build
    echo "  ✅ Archivos copiados correctamente"
ENDSSH

echo "  ✅ Archivos copiados a EC2"
echo ""

# ============================================================================
# PASO 4: Configurar Nginx para servir landing page en "/"
# ============================================================================

echo "⚙️  Paso 4: Configurando Nginx para servir landing page en '/'..."
echo ""

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP << 'ENDSSH'
    set -e
    
    # Asegurar que nginx esté instalado
    if ! command -v nginx &> /dev/null; then
        echo "  → Instalando nginx..."
        sudo dnf install -y -q nginx
    fi
    
    # Crear directorio de configuración si no existe
    sudo mkdir -p /etc/nginx/conf.d
    
    # Actualizar configuración de nginx para incluir landing page en "/"
    echo "  → Actualizando configuración de nginx..."
    sudo tee /etc/nginx/conf.d/shopping-app.conf > /dev/null << 'NGINXCONF'
server {
    listen 80;
    server_name _;
    
    # Archivos estáticos del landing (CSS, JS, imágenes) - DEBE ir ANTES de location /
    location ~ ^/(static|assets|favicon\.ico|manifest\.json|robots\.txt|logo) {
        root /var/www/html/landing;
        try_files $uri =404;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Landing page en raíz "/" - SPA de React
    location / {
        root /var/www/html/landing;
        try_files $uri $uri/ /index.html;
        index index.html;
    }
    
    # Health check directo (sin /api)
    location = /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
    
    # API Backend - debe ser específico para no interferir con landing
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_cache_bypass $http_upgrade;
        proxy_buffering off;
        
        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
        
        # Manejar preflight OPTIONS
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin * always;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
            add_header Access-Control-Max-Age 1728000;
            add_header Content-Type 'text/plain charset=UTF-8';
            add_header Content-Length 0;
            return 204;
        }
    }
    
    # App Flutter
    location /app {
        alias /var/www/html/app;
        try_files $uri $uri/ /app/index.html;
        index index.html;
        
        # Headers para Flutter web
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        
        # MIME types para JS/WASM
        location ~* \.(js|wasm)$ {
            add_header Content-Type application/javascript;
            add_header Cache-Control "public, max-age=31536000, immutable";
        }
        
        # CORS para Flutter
        add_header Access-Control-Allow-Origin * always;
    }
    
    # Portal Flutter
    location /portal {
        alias /var/www/html/portal;
        try_files $uri $uri/ /portal/index.html;
        index index.html;
        
        # Headers para Flutter web
        add_header Cache-Control "no-cache, no-store, must-revalidate" always;
        add_header Pragma "no-cache" always;
        add_header Expires "0" always;
        
        # MIME types para JS/WASM
        location ~* \.(js|wasm)$ {
            add_header Content-Type application/javascript;
            add_header Cache-Control "public, max-age=31536000, immutable";
        }
        
        # CORS para Flutter
        add_header Access-Control-Allow-Origin * always;
    }
    
    # Adminer
    location /adminer/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Rewrite para quitar /adminer del path
        rewrite ^/adminer/(.*)$ /$1 break;
    }
}
NGINXCONF
    
    # Probar configuración
    echo "  → Probando configuración de nginx..."
    if sudo nginx -t 2>&1; then
        echo "  ✅ Configuración de nginx válida"
    else
        echo "  ❌ ERROR: Configuración de nginx inválida"
        exit 1
    fi
    
    # Reiniciar nginx
    echo "  → Reiniciando nginx..."
    sudo systemctl restart nginx
    sudo systemctl enable nginx 2>/dev/null || true
    
    echo "  ✅ Nginx configurado y reiniciado"
ENDSSH

echo "  ✅ Nginx configurado correctamente"
echo ""

# ============================================================================
# PASO 5: Verificar deployment
# ============================================================================

echo "✅ Paso 5: Verificando deployment..."
echo ""

# Esperar un poco para que nginx se reinicie
sleep 2

# Verificar que el landing page esté accesible
if curl -s -f -m 5 "http://$PUBLIC_IP/" >/dev/null 2>&1; then
    echo "  ✅ Landing page accesible en http://$PUBLIC_IP/"
else
    echo "  ⚠️  Advertencia: No se pudo verificar el landing page"
    echo "  💡 Puede tardar unos segundos en estar disponible"
fi

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT DE LANDING PAGE COMPLETADO!"
echo "=========================================="
echo ""
echo "📍 Información:"
echo "   Instance ID: $INSTANCE_ID"
echo "   IP Pública: $PUBLIC_IP"
echo ""
echo "🌐 🌐 🌐 TU LANDING PAGE ESTÁ DISPONIBLE EN: 🌐 🌐 🌐"
echo "   👉 Landing: http://$PUBLIC_IP/ 👈"
echo "   👉 App: http://$PUBLIC_IP/app 👈"
echo "   👉 Portal: http://$PUBLIC_IP/portal 👈"
echo "   👉 API: http://$PUBLIC_IP/api 👈"
echo "   👉 Adminer: http://$PUBLIC_IP/adminer 👈"
echo ""
echo "=========================================="

