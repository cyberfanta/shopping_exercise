#!/bin/bash

###############################################################################
# SCRIPT DE DEPLOYMENT - Landing Page en GitHub Pages
###############################################################################
#
# Este script:
# 1. Crea una landing page simple en React
# 2. La despliega a GitHub Pages
# 3. Redirige a las dos apps Flutter
#
# CONFIGURACIÓN REQUERIDA:
# =======================
# 1. GITHUB_USERNAME: Tu usuario de GitHub
# 2. GITHUB_REPO: Nombre del repositorio
# 3. APP_URL: URL de la app Flutter (se proporcionará después)
# 4. PORTAL_URL: URL del portal Flutter (se proporcionará después)
# 5. GITHUB_TOKEN (opcional): Token de acceso personal
#
###############################################################################

# ============================================================================
# CONFIGURACIÓN - EDITA ESTOS VALORES
# ============================================================================

GITHUB_USERNAME="cyberfanta"         # ⚠️ REQUERIDO: Tu usuario de GitHub
GITHUB_REPO="shopping_exercise"      # ⚠️ REQUERIDO: Nombre del repositorio
APP_URL="http://100.49.43.143/app/"                 # ⚠️ REQUERIDO: URL de la app Flutter (ej: http://XX.XX.XX.XX)
PORTAL_URL="http://100.49.43.143/portal/"              # ⚠️ REQUERIDO: URL del portal Flutter (ej: http://YY.YY.YY.YY)
GITHUB_TOKEN=""            # Opcional: Token de acceso personal
REPO_NAME="landing-page"   # Nombre del repositorio para la landing page

# ============================================================================
# VALIDACIÓN
# ============================================================================

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ ERROR: GITHUB_USERNAME no está configurado"
    exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
    echo "❌ ERROR: GITHUB_REPO no está configurado"
    exit 1
fi

if [ -z "$APP_URL" ]; then
    echo "❌ ERROR: APP_URL no está configurado"
    exit 1
fi

if [ -z "$PORTAL_URL" ]; then
    echo "❌ ERROR: PORTAL_URL no está configurado"
    exit 1
fi

# ============================================================================
# CONFIGURACIÓN DE RUTAS
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR=$(mktemp -d)
LANDING_DIR="$TEMP_DIR/$REPO_NAME"

# Limpieza al salir
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# ============================================================================
# INICIO DEL DEPLOYMENT
# ============================================================================

echo "🚀 Iniciando deployment de Landing Page a GitHub Pages"
echo "======================================================="
echo "Usuario GitHub: $GITHUB_USERNAME"
echo "Repositorio: $GITHUB_REPO"
echo "App URL: $APP_URL"
echo "Portal URL: $PORTAL_URL"
echo ""

# ============================================================================
# PASO 1: Crear estructura del proyecto React
# ============================================================================

echo "📦 Paso 1: Creando estructura del proyecto React..."

mkdir -p "$LANDING_DIR"

# Crear package.json
cat > "$LANDING_DIR/package.json" << EOF
{
  "name": "shopping-landing-page",
  "version": "1.0.0",
  "description": "Landing page para Shopping Exercise",
  "private": true,
  "homepage": "https://${GITHUB_USERNAME}.github.io/${GITHUB_REPO}/",
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
EOF

# Crear public/index.html
mkdir -p "$LANDING_DIR/public"
cat > "$LANDING_DIR/public/index.html" << EOF
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
EOF

# Crear src/index.js
mkdir -p "$LANDING_DIR/src"
cat > "$LANDING_DIR/src/index.js" << 'EOF'
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
EOF

# Crear src/index.css
cat > "$LANDING_DIR/src/index.css" << 'EOF'
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
EOF

# Crear src/App.js
cat > "$LANDING_DIR/src/App.js" << 'EOF'
import React from 'react';
import './App.css';

function App() {
  const handleAppClick = () => {
    window.open(process.env.REACT_APP_APP_URL, '_blank');
  };

  const handlePortalClick = () => {
    window.open(process.env.REACT_APP_PORTAL_URL, '_blank');
  };

  return (
    <div className="App">
      <div className="container">
        <div className="content">
          <h1 className="title">🛒 Shopping Exercise</h1>
          <p className="subtitle">Plataforma de E-commerce</p>
          
          <div className="buttons">
            <button className="btn btn-primary" onClick={handleAppClick}>
              🛍️ Ir a la App
            </button>
            <button className="btn btn-secondary" onClick={handlePortalClick}>
              ⚙️ Ir al Portal Admin
            </button>
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
EOF

# Crear src/App.css
cat > "$LANDING_DIR/src/App.css" << 'EOF'
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
  max-width: 600px;
  width: 100%;
}

.content {
  display: flex;
  flex-direction: column;
  gap: 30px;
}

.title {
  font-size: 3rem;
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
  font-size: 1.2rem;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 600;
  text-decoration: none;
  display: inline-block;
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
    font-size: 2rem;
  }
  
  .subtitle {
    font-size: 1.2rem;
  }
  
  .buttons {
    flex-direction: column;
  }
  
  .btn {
    width: 100%;
  }
  
  .container {
    padding: 40px 20px;
  }
}
EOF

# Crear .gitignore
cat > "$LANDING_DIR/.gitignore" << 'EOF'
# Dependencies
/node_modules
/.pnp
.pnp.js

# Testing
/coverage

# Production
/build

# Misc
.DS_Store
.env.local
.env.development.local
.env.test.local
.env.production.local

npm-debug.log*
yarn-debug.log*
yarn-error.log*
EOF

# Crear README.md
cat > "$LANDING_DIR/README.md" << EOF
# Shopping Exercise - Landing Page

Landing page simple para redirigir a las aplicaciones Flutter.

## URLs

- App: $APP_URL
- Portal: $PORTAL_URL
EOF

echo "  ✅ Estructura creada"
echo ""

# ============================================================================
# PASO 2: Configurar variables de entorno
# ============================================================================

echo "⚙️  Paso 2: Configurando variables de entorno..."

# Crear .env.production
cat > "$LANDING_DIR/.env.production" << EOF
REACT_APP_APP_URL=$APP_URL
REACT_APP_PORTAL_URL=$PORTAL_URL
EOF

echo "  ✅ Variables configuradas"
echo ""

# ============================================================================
# PASO 3: Compilar React
# ============================================================================

echo "🏗️  Paso 3: Compilando aplicación React..."

cd "$LANDING_DIR"

# Verificar si Node.js está instalado
if ! command -v npm &> /dev/null; then
    echo "  ❌ ERROR: Node.js/npm no está instalado"
    echo "  💡 Instala Node.js desde https://nodejs.org/"
    exit 1
fi

# Instalar dependencias
echo "  → Instalando dependencias..."
npm install --silent

# Compilar
echo "  → Compilando para producción..."
npm run build

if [ $? -ne 0 ]; then
    echo "  ❌ ERROR: La compilación falló"
    exit 1
fi

echo "  ✅ Compilación completada"
echo ""

# ============================================================================
# PASO 4: Preparar para GitHub Pages
# ============================================================================

echo "📤 Paso 4: Preparando para GitHub Pages..."

cd "$TEMP_DIR"

# Configurar URL del repositorio
if [ -n "$GITHUB_TOKEN" ]; then
    REPO_URL="https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
else
    REPO_URL="https://github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git"
fi

# Clonar o inicializar repositorio
if git clone -b gh-pages "$REPO_URL" "$LANDING_DIR-deploy" 2>/dev/null; then
    DEPLOY_DIR="$LANDING_DIR-deploy"
    cd "$DEPLOY_DIR"
else
    # Crear nuevo repositorio
    DEPLOY_DIR="$TEMP_DIR/gh-pages"
    mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    git init
    git checkout -b gh-pages
fi

# Limpiar contenido anterior
rm -rf ./* .[^.]* 2>/dev/null || true

# Copiar build
cp -r "$LANDING_DIR/build"/* .

# Crear .nojekyll
touch .nojekyll

echo "  ✅ Archivos preparados"
echo ""

# ============================================================================
# PASO 5: Commit y Push
# ============================================================================

echo "📤 Paso 5: Subiendo a GitHub Pages..."

git config user.name "${GITHUB_USERNAME}" || true
git config user.email "${GITHUB_USERNAME}@users.noreply.github.com" || true

git add -A

if git diff --staged --quiet; then
    echo "  ⚠️  No hay cambios para commitear"
else
    git commit -m "Deploy landing page - $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ -d "$LANDING_DIR-deploy" ]; then
        # Ya era un repositorio clonado
        git push origin gh-pages
    else
        # Nuevo repositorio, agregar remote y push
        git remote add origin "$REPO_URL"
        git push -u origin gh-pages
    fi
    
    if [ $? -eq 0 ]; then
        echo "  ✅ Push completado exitosamente"
    else
        echo "  ❌ ERROR: El push falló"
        exit 1
    fi
fi

echo ""
echo "======================================================="
echo "✅ Deployment de Landing Page completado!"
echo ""
echo "🌐 Tu landing page está disponible en:"
echo "   https://${GITHUB_USERNAME}.github.io/${GITHUB_REPO}/"
echo ""
echo "⏱️  Puede tardar unos minutos en estar disponible"
echo "======================================================="

