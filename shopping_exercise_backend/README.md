# Shopping Exercise Backend

Backend completo con Docker para el e-commerce Shopping Exercise.

## 🚀 Características

- **Autenticación completa**: Registro, login, reset de contraseña con email
- **Gestión de productos**: CRUD completo con categorías
- **Carrito de compras**: Agregar, actualizar, eliminar productos
- **Sistema de órdenes**: Checkout completo con simulación de pagos
- **Base de datos PostgreSQL** con datos de ejemplo
- **API REST** con documentación completa

## 📦 Requisitos

- Docker y Docker Compose
- Node.js 22 (para desarrollo local sin Docker)

## 🛠️ Instalación

1. Clonar el repositorio
2. Navegar a la carpeta del backend:
```bash
cd shopping_exercise_backend
```

3. Crear archivo de variables de entorno:
```bash
cp api/.env.example api/.env
```

4. Editar `api/.env` con tus credenciales (especialmente las de email SMTP)

5. Iniciar los contenedores:
```bash
docker-compose up -d
```

## 📡 Servicios

- **API**: http://localhost:3000
- **Adminer** (UI de base de datos): http://localhost:8080
- **PostgreSQL**: localhost:5432

## 📚 Documentación

Ver la documentación completa de endpoints en: [API_ENDPOINTS.md](./API_ENDPOINTS.md)

## 🔑 Acceso a la Base de Datos

Para acceder a Adminer (http://localhost:8080):
- Sistema: PostgreSQL
- Servidor: postgres
- Usuario: postgres
- Contraseña: postgres123
- Base de datos: shopping_db

## 🧪 Pruebas

El sistema incluye datos de ejemplo:
- 5 categorías
- 5 productos de muestra

## 📝 Notas

- El endpoint de reset de contraseña requiere configurar SMTP
- Para Gmail, necesitas crear una "App Password" en tu cuenta
- En producción, cambiar JWT_SECRET y credenciales de base de datos

