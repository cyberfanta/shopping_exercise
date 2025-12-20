# Actualización del Backend - Nuevas Funcionalidades

## 🆕 Cambios en la Base de Datos

### Tabla `users`
- **Nuevo campo**: `role` VARCHAR(20) - Puede ser: 'user', 'admin', 'superadmin'
- **Índice**: `idx_users_role` para búsquedas por rol

### Tabla `products`
- **Nuevos campos para YouTube**:
  - `youtube_video_id` VARCHAR(100) - ID del video de YouTube
  - `youtube_thumbnail` VARCHAR(500) - URL del thumbnail
  - `youtube_duration` VARCHAR(20) - Duración del video

### Superadmin por Defecto
- **Email**: julioleon2004@gmail.com
- **Password**: Admin123!
- **Rol**: superadmin
- ⚠️ **No puede ser eliminado ni desactivado**

## 📡 Nuevos Endpoints

### Gestión de Usuarios (Admin)
```
GET    /api/users              # Listar usuarios (con paginación y filtros)
GET    /api/users/:id          # Obtener usuario por ID
PUT    /api/users/:id          # Actualizar usuario
DELETE /api/users/:id          # Eliminar usuario (soft delete)
```

**Notas**:
- Requiere autenticación y rol admin/superadmin
- Solo superadmin puede asignar roles de admin/superadmin
- El superadmin (julioleon2004@gmail.com) no puede ser eliminado

### YouTube API
```
GET /api/youtube/search?q=query&maxResults=10    # Buscar videos
GET /api/youtube/video/:videoId                   # Detalles de video
```

**Notas**:
- Requiere YOUTUBE_API_KEY en .env
- Si no hay API key, devuelve datos de ejemplo

## 🔐 Actualización del Sistema de Auth

### JWT ahora incluye el rol
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "role": "superadmin"
}
```

### Login devuelve el rol
```json
{
  "user": {
    "id": "...",
    "email": "...",
    "role": "superadmin",
    ...
  },
  "token": "..."
}
```

## 🛡️ Middleware de Admin

Nuevo middleware `admin.middleware.js` que verifica:
- Usuario autenticado
- Rol admin o superadmin

## 📦 Nuevas Dependencias

- `axios`: ^1.6.2 (para llamadas a YouTube API)

## 🚀 Cómo Actualizar

1. **Detener los contenedores**:
```bash
docker-compose down
```

2. **Eliminar volumen de base de datos** (para aplicar cambios en schema):
```bash
docker volume rm shopping_exercise_backend_postgres_data
```

3. **Configurar YouTube API** (opcional):
- Obtener API key en https://console.developers.google.com/
- Agregar `YOUTUBE_API_KEY=tu-key-aqui` en `api/.env`

4. **Reconstruir y levantar**:
```bash
docker-compose up -d --build
```

5. **Verificar**:
```bash
docker-compose logs -f api
```

La base de datos se inicializará con:
- 5 categorías
- 5 productos de ejemplo (con videos de YouTube)
- 1 superadmin (julioleon2004@gmail.com)

## 🎯 Ejemplo de Uso

### Crear producto con YouTube
```bash
curl -X POST http://localhost:3000/api/products \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Tutorial de Flutter",
    "description": "Aprende Flutter desde cero",
    "price": 29.99,
    "stock": 999,
    "youtube_video_id": "CD1Y2DJL81M",
    "category_id": "category-uuid"
  }'
```

### Buscar videos de YouTube
```bash
curl "http://localhost:3000/api/youtube/search?q=flutter+tutorial&maxResults=5" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Listar usuarios (solo admin)
```bash
curl "http://localhost:3000/api/users?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```


