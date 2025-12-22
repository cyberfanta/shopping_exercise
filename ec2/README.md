# Scripts de Deployment a EC2

Esta carpeta contiene scripts para desplegar el proyecto directamente en instancias EC2.

## Scripts Disponibles

### 1. `deploy_backend_ec2.sh`

Despliega el backend en una instancia EC2 con Docker.

**Características:**

- Crea instancia EC2 t3.micro (free tier)
- Instala Docker y Docker Compose
- Clona el repositorio desde GitHub
- Levanta contenedores Docker (solo internos)

**Configuración requerida:**

```bash
# KEY_PAIR_NAME ya está configurado por defecto: aws-eb-shopping-exercise
# GITHUB_REPO_URL ya está configurado por defecto: git@github.com:cyberfanta/shopping_exercise.git
# EC2_INSTANCE_NAME ya tiene valor por defecto: shopping-backend
# 
# ⚠️ IMPORTANTE: Asegúrate de tener el archivo de clave en ~/.ssh/aws-eb-shopping-exercise
#    o ~/.ssh/aws-eb-shopping-exercise.pem
```

### 2. `deploy_app_flutter_ec2.sh`

Despliega la app Flutter en una instancia EC2 con nginx.

**Características:**

- Crea instancia EC2 t3.micro
- Instala Flutter, nginx
- Compila Flutter Web en modo release
- Configura nginx para servir la app
- Expone HTTP (80) y HTTPS (443)

**Configuración requerida:**

```bash
# KEY_PAIR_NAME ya está configurado: aws-eb-shopping-exercise
# GITHUB_REPO_URL ya está configurado por defecto
# EC2_INSTANCE_NAME ya tiene valor por defecto: shopping-app
```

### 3. `deploy_portal_flutter_ec2.sh`

Despliega el portal Flutter en una instancia EC2 con nginx.

**Características:**

- Igual que el script de la app, pero para el portal

**Configuración requerida:**

```bash
# KEY_PAIR_NAME ya está configurado: aws-eb-shopping-exercise
# GITHUB_REPO_URL ya está configurado por defecto
# EC2_INSTANCE_NAME ya tiene valor por defecto: shopping-portal
```

### 4. `deploy_github_pages_landing.sh`

Crea y despliega una landing page en GitHub Pages.

**Características:**

- Crea una landing page simple en React
- Redirige a las dos apps Flutter
- Despliega a GitHub Pages

**Configuración requerida:**

```bash
# GITHUB_USERNAME y GITHUB_REPO ya están configurados por defecto
APP_URL="http://XX.XX.XX.XX"  # ⚠️ REQUERIDO: URL de la app (obtener después de ejecutar deploy_app_flutter_ec2.sh)
PORTAL_URL="http://YY.YY.YY.YY"  # ⚠️ REQUERIDO: URL del portal (obtener después de ejecutar deploy_portal_flutter_ec2.sh)
```

## Prerrequisitos

1. **AWS CLI** instalado y configurado
   ```bash
   aws configure
   ```

2. **Key Pair de AWS** configurado
    - El key pair `aws-eb-shopping-exercise` ya está configurado en los scripts
    - Asegúrate de tener el archivo de clave en `~/.ssh/aws-eb-shopping-exercise`
    - O en `~/.ssh/aws-eb-shopping-exercise.pem`
    - Si no lo tienes, descárgalo desde AWS Console → EC2 → Key Pairs

3. **Permisos IAM** necesarios:
    - `ec2:RunInstances`
    - `ec2:DescribeInstances`
    - `ec2:CreateSecurityGroup`
    - `ec2:AuthorizeSecurityGroupIngress`
    - `ec2:StartInstances`
    - `ec2:DescribeImages`

4. **Node.js y npm** (solo para el script de GitHub Pages)
    - Instalar desde https://nodejs.org/

## Uso

### 1. Configurar SSH Key (PRIMERO)

**IMPORTANTE**: Antes de ejecutar los scripts de deployment, configura la clave SSH:

```bash
# Opción 1: Si ya tienes la clave, cópiala a la raíz del proyecto
cp ~/.ssh/aws-eb-shopping-exercise.pem ./aws-eb-shopping-exercise.pem
chmod 400 ./aws-eb-shopping-exercise.pem

# Opción 2: Usar el script de configuración (crea nueva clave si no existe)
./scripts/ec2/setup_ssh_key.sh
```

El script buscará la clave en:

- `~/.ssh/aws-eb-shopping-exercise.pem`
- `~/.ssh/aws-eb-shopping-exercise`
- `./aws-eb-shopping-exercise.pem` (raíz del proyecto)

**Nota**: Si perdiste la clave, el script `setup_ssh_key.sh` puede crear una nueva (eliminará la
existente en AWS).

**Nota:** Los scripts ya tienen configurados:

- `KEY_PAIR_NAME="aws-eb-shopping-exercise"`
- `GITHUB_REPO_URL="git@github.com:cyberfanta/shopping_exercise.git"`
- Nombres de instancias por defecto

Solo necesitas configurar `APP_URL` y `PORTAL_URL` en el script de landing page después de ejecutar
los otros scripts.

### 2. Dar permisos de ejecución

```bash
chmod +x scripts/ec2/*.sh
```

### 3. Ejecutar los scripts

```bash
# Backend
./scripts/ec2/deploy_backend_ec2.sh

# App Flutter
./scripts/ec2/deploy_app_flutter_ec2.sh

# Portal Flutter
./scripts/ec2/deploy_portal_flutter_ec2.sh

# Landing Page (después de obtener las URLs)
./scripts/ec2/deploy_github_pages_landing.sh
```

## Orden Recomendado de Deployment

1. **Backend primero**: `deploy_backend_ec2.sh`
    - API disponible en: `http://[IP_BACKEND]:3000`

2. **App Flutter**: `deploy_app_flutter_ec2.sh`
    - Crea/usa instancia `shopping-flutter`
    - App disponible en: `http://[IP_FLUTTER]/app`

3. **Portal Flutter**: `deploy_portal_flutter_ec2.sh`
    - Usa la misma instancia `shopping-flutter` que la app
    - Portal disponible en: `http://[IP_FLUTTER]/portal`
    - **Nota**: Ambas apps comparten la misma IP pública

4. **Landing Page**: Configura las URLs en `deploy_github_pages_landing.sh` y ejecuta
    - Usa: `http://[IP_FLUTTER]/app` y `http://[IP_FLUTTER]/portal`

## Costos

- **EC2 t3.micro**: Elegible para free tier (750 horas/mes por 12 meses)
- **EBS Storage**: 30 GB incluidos en free tier
- **Data Transfer**: Primeros 100 GB/mes gratis

## 🔐 Conexión SSH a las Instancias

Después del deployment, puedes conectarte por SSH:

```bash
# Usar el script de conexión (recomendado)
./scripts/ec2/connect_ssh.sh shopping-backend
./scripts/ec2/connect_ssh.sh shopping-app
./scripts/ec2/connect_ssh.sh shopping-portal

# O manualmente
ssh -i ~/.ssh/aws-eb-shopping-exercise.pem ec2-user@[IP_PUBLICA]
```

**Ver guía completa**: [SSH_CONNECTION_GUIDE.md](./SSH_CONNECTION_GUIDE.md)

## Troubleshooting

### Error: "No se encuentra el archivo de clave"

- Asegúrate de que el archivo `.pem` esté en `~/.ssh/`
- Verifica que el nombre del key pair sea correcto

### Error: "Timeout esperando SSH"

- Espera un poco más (las instancias pueden tardar 1-2 minutos en iniciar)
- Verifica que el security group permita SSH (puerto 22)

### Error al clonar repositorio

- Verifica que el repositorio sea público o que tengas un `GITHUB_TOKEN`
- Verifica que la URL del repositorio sea correcta

### nginx no sirve la página

- Verifica que nginx esté corriendo: `sudo systemctl status nginx`
- Revisa los logs: `sudo tail -f /var/log/nginx/error.log`
- Verifica que el puerto 80 esté abierto en el security group

## Notas Importantes

- Las instancias EC2 se pueden detener/terminar desde AWS Console para ahorrar costos
- Las IPs públicas pueden cambiar al reiniciar (considera usar Elastic IP para IPs fijas)
- Los contenedores Docker del backend están expuestos solo internamente
- Para producción, considera usar HTTPS con Let's Encrypt o AWS Certificate Manager

