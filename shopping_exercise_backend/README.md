# Shopping Exercise Backend

Backend completo con Docker para el e-commerce Shopping Exercise.

## 🚀 Características

- **Autenticación completa**: Registro, login, reset de contraseña con email
- **Integración con YouTube**: Búsqueda de videos con filtros avanzados
- **Gestión de productos**: Videos de YouTube como productos
- **Categorías automáticas**: Basadas en canales de YouTube
- **Carrito de compras**: Agregar, actualizar, eliminar productos
- **Sistema de órdenes**: Checkout completo con simulación de pagos
- **Gestión de usuarios**: Roles (user, admin, superadmin)
- **Base de datos PostgreSQL**
- **API REST** con documentación completa

## 📦 Requisitos

- Docker y Docker Compose
- Node.js 22 (para desarrollo local sin Docker)
- **YouTube Data API Key** (ver guía abajo)

## 🛠️ Instalación

1. Clonar el repositorio

2. Navegar a la carpeta del backend:
```bash
cd shopping_exercise_backend
```

3. **Obtener YouTube API Key** (requerido):
   - Sigue la guía: [YOUTUBE_API_KEY_GUIDE.md](./YOUTUBE_API_KEY_GUIDE.md)

4. Crear archivo de variables de entorno:
```bash
cp api/.env.example api/.env
```

5. Editar `api/.env` con tus credenciales:
```env
# ... otras variables ...
YOUTUBE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

6. Iniciar los contenedores:
```bash
docker-compose up -d --build
```

7. Verificar que todo funciona:
```bash
docker logs shopping_api --tail 20
```

## 📡 Servicios

- **API**: http://localhost:3000
  - Health check: http://localhost:3000/health
- **Adminer** (UI de base de datos): http://localhost:8080
- **PostgreSQL**: localhost:5432

## 📚 Documentación

- **[API_ENDPOINTS.md](./API_ENDPOINTS.md)** - Documentación completa de endpoints
- **[YOUTUBE_API_KEY_GUIDE.md](./YOUTUBE_API_KEY_GUIDE.md)** - Cómo obtener YouTube API Key
- **[IMPLEMENTACION_COMPLETADA.md](./IMPLEMENTACION_COMPLETADA.md)** - Guía de uso y funcionalidades

## 🔑 Acceso a la Base de Datos

Para acceder a Adminer (http://localhost:8080):
- Sistema: PostgreSQL
- Servidor: **postgres** (nombre del servicio Docker)
- Usuario: postgres
- Contraseña: postgres123
- Base de datos: shopping_db

## 👤 Usuario por Defecto

**Superadmin:**
- Email: `julioleon2004@gmail.com`
- Password: `Admin123!`
- Rol: superadmin (no puede ser eliminado)

## 🎥 Funcionalidades de YouTube

### Búsqueda de Videos
El backend permite buscar videos de YouTube con filtros:
- Ordenamiento: relevance, date, viewCount, rating, title
- Duración: any, short (<4min), medium (4-20min), long (>20min)
- Fecha de publicación

### Precio Automático
Los videos tienen un precio calculado por vistas:
```
Precio = $5.00 + (vistas / 100,000) * $1.50
Rango: $5.00 - $99.99
```

### Categorías Automáticas
- Las categorías se crean automáticamente por canal de YouTube
- Cada canal tiene su propia categoría
- Los videos se agrupan por canal

## 🧪 Datos de Ejemplo

La base de datos inicia sin datos de ejemplo. Los productos se agregan desde el portal usando la búsqueda de YouTube.

Para limpiar datos si es necesario:
```bash
docker-compose exec postgres psql -U postgres -d shopping_db -f /docker-entrypoint-initdb.d/clean_sample_data.sql
```

## 🔧 Comandos Útiles

```bash
# Ver logs del API
docker logs shopping_api --tail 50 -f

# Ver logs de la base de datos
docker logs shopping_postgres --tail 20

# Reiniciar servicios
docker-compose restart api

# Detener todo
docker-compose down

# Recrear desde cero (borra datos)
docker-compose down
docker volume rm shopping_exercise_backend_postgres_data
docker-compose up -d --build
```

## 📝 Notas

- **YouTube API:** Configura `YOUTUBE_API_KEY` para usar la búsqueda de videos
- **SMTP:** Configura credenciales SMTP para reset de contraseña
- **Gmail:** Necesitas crear una "App Password" para Gmail
- **Producción:** Cambia `JWT_SECRET` y credenciales de base de datos
- **Cuota YouTube:** 10,000 unidades/día gratuitas (~100 búsquedas)

## 🐛 Troubleshooting

### YouTube API no funciona
1. Verifica que `YOUTUBE_API_KEY` esté en `api/.env`
2. Reinicia el container: `docker-compose restart api`
3. Revisa logs: `docker logs shopping_api`

### No puedo conectar a Adminer
- Usa `postgres` como servidor (no `localhost`)
- Verifica que el container esté corriendo: `docker ps`

### Error al iniciar
- Verifica que Docker Desktop esté corriendo
- Asegúrate que los puertos 3000, 5432, 8080 estén libres

---

**¿Necesitas ayuda?** Revisa la guía completa en [IMPLEMENTACION_COMPLETADA.md](./IMPLEMENTACION_COMPLETADA.md)


