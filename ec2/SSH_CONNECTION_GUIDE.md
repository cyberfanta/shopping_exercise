# Guía de Conexión SSH a Instancias EC2

## 🔐 Métodos de Conexión

### Método 1: Usando el script de conexión (Recomendado)

```bash
# Conectar al backend
./scripts/ec2/connect_ssh.sh shopping-backend

# Conectar a la app
./scripts/ec2/connect_ssh.sh shopping-app

# Conectar al portal
./scripts/ec2/connect_ssh.sh shopping-portal
```

### Método 2: Conexión SSH manual

```bash
# 1. Buscar la IP pública de la instancia
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=shopping-backend" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# 2. Conectar (reemplaza XX.XX.XX.XX con la IP)
ssh -i ~/.ssh/aws-eb-shopping-exercise.pem ec2-user@XX.XX.XX.XX

# O si la clave está en la raíz del proyecto:
ssh -i ./aws-eb-shopping-exercise.pem ec2-user@XX.XX.XX.XX
```

### Método 3: SFTP (para transferir archivos)

SFTP usa SSH como protocolo subyacente, así que necesitas la misma clave:

```bash
# Conectar por SFTP
sftp -i ~/.ssh/aws-eb-shopping-exercise.pem ec2-user@XX.XX.XX.XX

# O desde la raíz del proyecto:
sftp -i ./aws-eb-shopping-exercise.pem ec2-user@XX.XX.XX.XX
```

## 📋 Ubicaciones del archivo de clave

El script busca la clave en este orden:

1. `~/.ssh/aws-eb-shopping-exercise.pem`
2. `~/.ssh/aws-eb-shopping-exercise`
3. `./aws-eb-shopping-exercise.pem` (raíz del proyecto)

## 🔑 Si no tienes la clave

### Opción 1: Crear nueva clave (elimina la existente en AWS)

```bash
./scripts/ec2/setup_ssh_key.sh
```

Este script:

- Verifica si existe la clave localmente
- Si no existe, crea una nueva en AWS
- La descarga y guarda en el proyecto

### Opción 2: Verificar información del key pair

```bash
./scripts/ec2/get_ssh_key_from_aws.sh
```

## 📝 Comandos útiles una vez conectado

```bash
# Ver historial de comandos del deployment
cat /tmp/ec2_deployment_history_*.log

# Ver contenedores Docker (backend)
cd shopping_exercise/shopping_exercise_backend
sudo docker-compose ps

# Ver logs de nginx (app/portal)
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Ver estado de servicios
sudo systemctl status nginx
sudo systemctl status docker

# Ver espacio en disco
df -h

# Ver procesos
ps aux
```

## 🔒 Seguridad

- **SSH está restringido** solo desde tu IP: `38.74.224.33`
- Si tu IP cambia, necesitarás actualizar el security group
- El usuario por defecto en Amazon Linux es: `ec2-user`

## 🐛 Troubleshooting

### Error: "Permission denied (publickey)"

**Solución:**

1. Verifica que el archivo de clave existe
2. Verifica los permisos: `chmod 400 aws-eb-shopping-exercise.pem`
3. Verifica que estás usando el usuario correcto: `ec2-user`

### Error: "Connection timed out"

**Solución:**

1. Verifica que la instancia está en estado "running"
2. Verifica que tu IP está permitida en el security group
3. Verifica que el security group permite SSH (puerto 22)

### Error: "WARNING: UNPROTECTED PRIVATE KEY FILE!"

**Solución:**

```bash
chmod 400 aws-eb-shopping-exercise.pem
```

