# Shopping Exercise - API Endpoints

Base URL: `http://localhost:3000/api`

---

## 🔐 Autenticación

### Registrar Usuario
```http
POST /auth/register
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "password123",
  "first_name": "Juan",
  "last_name": "Pérez",
  "phone": "+34612345678"
}
```

**Respuesta:**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": "uuid",
    "email": "usuario@ejemplo.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "phone": "+34612345678",
    "role": "user",
    "created_at": "2025-12-20T10:00:00.000Z"
  },
  "token": "jwt_token_here"
}
```

---

### Iniciar Sesión
```http
POST /auth/login
Content-Type: application/json

{
  "email": "usuario@ejemplo.com",
  "password": "password123"
}
```

**Respuesta:**
```json
{
  "message": "Login successful",
  "user": {
    "id": "uuid",
    "email": "usuario@ejemplo.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "phone": "+34612345678",
    "role": "user",
    "is_active": true
  },
  "token": "jwt_token_here"
}
```

---

## 🎥 YouTube Search

### Buscar Videos de YouTube (Protegido)
```http
GET /youtube/search?q=flutter&order=viewCount&videoDuration=medium
Authorization: Bearer {token}
```

**Parámetros de Query:**
- `q` (requerido): Término de búsqueda
- `maxResults` (opcional): Número de resultados (1-50, por defecto: 10)
- `order` (opcional): Criterio de ordenamiento
  - `relevance` (por defecto): Relevancia
  - `date`: Fecha de publicación
  - `viewCount`: Número de vistas
  - `rating`: Calificación
  - `title`: Título alfabético
- `videoDuration` (opcional): Filtro por duración
  - `any` (por defecto): Cualquier duración
  - `short`: Corto (< 4 minutos)
  - `medium`: Medio (4-20 minutos)
  - `long`: Largo (> 20 minutos)
- `publishedAfter` (opcional): Fecha en formato ISO 8601 (ej: 2023-01-01T00:00:00Z)

**Respuesta:**
```json
{
  "videos": [
    {
      "videoId": "CD1Y2DJL81M",
      "title": "Flutter Tutorial Completo",
      "description": "Aprende Flutter desde cero...",
      "thumbnail": "https://i.ytimg.com/vi/CD1Y2DJL81M/hqdefault.jpg",
      "channelId": "UCmXVXfidLZQkppLPaATcHag",
      "channelTitle": "Flutter",
      "publishedAt": "2023-01-15T10:30:00Z",
      "viewCount": 150000,
      "likeCount": 5000,
      "duration": "PT15M30S",
      "suggestedPrice": 7.25
    }
  ]
}
```

**Cálculo de Precio:**
- Precio base: $5.00
- Fórmula: `$5 + (vistas / 100,000) * $1.50`
- Rango: $5.00 - $99.99

---

### Obtener Detalles de Video (Protegido)
```http
GET /youtube/video/{videoId}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "video": {
    "videoId": "CD1Y2DJL81M",
    "title": "Flutter Tutorial",
    "description": "Full description...",
    "thumbnail": "https://i.ytimg.com/vi/CD1Y2DJL81M/hqdefault.jpg",
    "channelId": "UCmXVXfidLZQkppLPaATcHag",
    "channelTitle": "Flutter",
    "publishedAt": "2023-01-15T10:30:00Z",
    "duration": "PT15M30S",
    "viewCount": 150000,
    "likeCount": 5000,
    "suggestedPrice": 7.25
  }
}
```

---

## 📦 Productos

### Listar Productos
```http
GET /products?page=1&limit=10&category_id=uuid&search=laptop
```

**Parámetros de Query:**
- `page` (opcional): Número de página (por defecto: 1)
- `limit` (opcional): Productos por página (por defecto: 10)
- `category_id` (opcional): Filtrar por categoría
- `search` (opcional): Buscar en nombre y descripción

**Respuesta:**
```json
{
  "products": [
    {
      "id": "uuid",
      "category_id": "uuid",
      "category_name": "Flutter",
      "name": "Flutter Tutorial Completo",
      "description": "Aprende Flutter...",
      "price": "7.25",
      "discount_price": null,
      "stock": 999,
      "youtube_video_id": "CD1Y2DJL81M",
      "youtube_channel_id": "UCmXVXfidLZQkppLPaATcHag",
      "youtube_thumbnail": "https://i.ytimg.com/vi/CD1Y2DJL81M/hqdefault.jpg",
      "youtube_duration": "PT15M30S",
      "is_active": true,
      "created_at": "2025-12-20T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "totalItems": 25,
    "totalPages": 3
  }
}
```

---

### Obtener Producto por ID
```http
GET /products/{id}
```

**Respuesta:**
```json
{
  "product": {
    "id": "uuid",
    "name": "Flutter Tutorial",
    "description": "...",
    "price": "7.25",
    "stock": 999,
    "youtube_video_id": "CD1Y2DJL81M",
    "youtube_thumbnail": "...",
    ...
  }
}
```

---

### Crear Producto (Protegido)
```http
POST /products
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Flutter Tutorial Completo",
  "description": "Aprende Flutter desde cero",
  "price": 7.25,
  "stock": 999,
  "youtube_video_id": "CD1Y2DJL81M",
  "youtube_channel_id": "UCmXVXfidLZQkppLPaATcHag",
  "youtube_channel_name": "Flutter",
  "youtube_thumbnail": "https://i.ytimg.com/vi/CD1Y2DJL81M/hqdefault.jpg",
  "youtube_duration": "PT15M30S"
}
```

**Notas:**
- Si se proporcionan `youtube_channel_id` y `youtube_channel_name`, se creará/obtendrá automáticamente una categoría para ese canal.
- Las categorías se crean automáticamente basadas en los canales de YouTube.

**Respuesta:**
```json
{
  "message": "Product created successfully",
  "product": { ... }
}
```

---

### Crear Múltiples Productos (Protegido)
```http
POST /products/bulk
Authorization: Bearer {token}
Content-Type: application/json

{
  "products": [
    {
      "name": "Video Tutorial 1",
      "description": "Descripción del video 1",
      "price": 29.99,
      "stock": 999,
      "youtube_video_id": "video_id_1",
      "youtube_channel_id": "channel_id_1",
      "youtube_channel_name": "Canal 1",
      "youtube_thumbnail": "thumbnail_url_1",
      "youtube_duration": "PT15M30S"
    },
    {
      "name": "Video Tutorial 2",
      "description": "Descripción del video 2",
      "price": 39.99,
      "stock": 999,
      "youtube_video_id": "video_id_2",
      "youtube_channel_id": "channel_id_2",
      "youtube_channel_name": "Canal 2",
      "youtube_thumbnail": "thumbnail_url_2",
      "youtube_duration": "PT20M15S"
    }
  ]
}
```

**Respuesta:**
```json
{
  "message": "2 products created successfully",
  "products": [ ... ],
  "errors": []
}
```

---

### Actualizar Producto (Protegido)
```http
PUT /products/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Nuevo nombre",
  "price": 35.99,
  "stock": 50,
  "is_active": true
}
```

**Respuesta:**
```json
{
  "message": "Product updated successfully",
  "product": { ... }
}
```

---

### Eliminar Producto (Protegido - Soft Delete)
```http
DELETE /products/{id}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "Product deleted successfully"
}
```

---

## 📂 Categorías

### Listar Categorías
```http
GET /categories?page=1&limit=10
```

**Respuesta:**
```json
{
  "categories": [
    {
      "id": "uuid",
      "name": "Flutter",
      "description": "Videos del canal: Flutter",
      "is_active": true,
      "created_at": "2025-12-20T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "totalItems": 5,
    "totalPages": 1
  }
}
```

**Nota:** Las categorías se crean automáticamente al agregar productos de YouTube basándose en los nombres de canales.

---

## 🛒 Carrito de Compras

### Ver Carrito (Protegido)
```http
GET /cart
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "cart": {
    "id": "uuid",
    "items": [
      {
        "id": "uuid",
        "product_id": "uuid",
        "product_name": "Flutter Tutorial",
        "price": "7.25",
        "quantity": 2,
        "subtotal": "14.50",
        "youtube_thumbnail": "..."
      }
    ],
    "subtotal": "14.50"
  }
}
```

---

### Agregar Producto al Carrito (Protegido)
```http
POST /cart
Authorization: Bearer {token}
Content-Type: application/json

{
  "product_id": "uuid",
  "quantity": 2
}
```

**Respuesta:**
```json
{
  "message": "Product added to cart successfully",
  "cartItem": { ... }
}
```

---

### Actualizar Cantidad en Carrito (Protegido)
```http
PUT /cart/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "quantity": 3
}
```

**Respuesta:**
```json
{
  "message": "Cart item updated successfully",
  "cartItem": { ... }
}
```

---

### Eliminar del Carrito (Protegido)
```http
DELETE /cart/{id}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "Cart item removed successfully"
}
```

---

### Vaciar Carrito (Protegido)
```http
DELETE /cart
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "Cart cleared successfully"
}
```

---

## 📋 Pedidos

### Listar Pedidos (Protegido)
```http
GET /orders?page=1&limit=10&status=confirmed
Authorization: Bearer {token}
```

**Parámetros de Query:**
- `page` (opcional): Número de página
- `limit` (opcional): Pedidos por página
- `status` (opcional): Filtrar por estado

**Respuesta:**
```json
{
  "orders": [
    {
      "id": "uuid",
      "order_number": "ORD-1234567890-ABC123",
      "status": "confirmed",
      "subtotal": "2599.98",
      "tax": "415.99",
      "shipping": "50.00",
      "total": "3065.97",
      "payment_status": "paid",
      "payment_method": "credit_card",
      "items_count": 2,
      "created_at": "2025-12-20T10:00:00.000Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Crear Pedido / Checkout (Protegido)
```http
POST /orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "payment_method": "credit_card",
  "shipping_address": {
    "street": "Calle Principal 123",
    "city": "Madrid",
    "state": "Madrid",
    "zip": "28001",
    "country": "España"
  },
  "notes": "Notas adicionales del pedido"
}
```

**Respuesta:**
```json
{
  "message": "Order created successfully",
  "order": {
    "id": "uuid",
    "order_number": "ORD-1234567890-ABC123",
    "status": "pending",
    "total": "3065.97",
    ...
  }
}
```

**Notas:**
- El carrito se vaciará automáticamente después de crear el pedido
- El stock de productos se reducirá automáticamente
- Se calcula automáticamente:
  - IVA (16% del subtotal)
  - Envío (gratis si el subtotal > $500, sino $50)

---

### Simular Pago (Protegido)
```http
POST /orders/{id}/pay
Authorization: Bearer {token}
```

**Respuesta (Éxito):**
```json
{
  "message": "Payment processed successfully",
  "payment_status": "paid",
  "order_status": "confirmed"
}
```

---

## 👥 Gestión de Usuarios (Admin)

### Listar Usuarios (Admin)
```http
GET /users?page=1&limit=10&search=juan
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "users": [
    {
      "id": "uuid",
      "email": "usuario@ejemplo.com",
      "first_name": "Juan",
      "last_name": "Pérez",
      "phone": "+34612345678",
      "role": "user",
      "is_active": true,
      "created_at": "2025-12-20T10:00:00.000Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Actualizar Usuario (Admin)
```http
PUT /users/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "first_name": "Juan Carlos",
  "role": "admin",
  "is_active": true
}
```

**Nota:** El usuario superadmin (`julioleon2004@gmail.com`) no puede ser modificado ni eliminado.

**Respuesta:**
```json
{
  "message": "User updated successfully",
  "user": { ... }
}
```

---

### Eliminar Usuario (Admin - Soft Delete)
```http
DELETE /users/{id}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "User deleted successfully"
}
```

**Nota:** El usuario superadmin no puede ser eliminado.

---

## 🛒 Gestión de Carritos (Admin)

### Listar Todos los Carritos (Admin)
```http
GET /admin/carts?page=1&limit=20
Authorization: Bearer {token}
```

**Parámetros de Query:**
- `page` (opcional): Número de página (por defecto: 1)
- `limit` (opcional): Carritos por página (por defecto: 20)

**Respuesta:**
```json
{
  "carts": [
    {
      "cart_id": "uuid",
      "user_id": "uuid",
      "user_email": "usuario@ejemplo.com",
      "first_name": "Juan",
      "last_name": "Pérez",
      "items_count": 3,
      "subtotal": "84.97",
      "updated_at": "2025-12-20T10:00:00.000Z",
      "items": [
        {
          "id": "uuid",
          "product_id": "uuid",
          "product_name": "Tutorial de Flutter",
          "price": 29.99,
          "quantity": 2,
          "subtotal": 59.98,
          "youtube_thumbnail": "https://i.ytimg.com/vi/..."
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalItems": 5,
    "totalPages": 1
  }
}
```

**Nota:** Solo muestra carritos con items.

---

### Obtener Carrito por Usuario (Admin)
```http
GET /admin/carts/{userId}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "cart": {
    "cart_id": "uuid",
    "user_id": "uuid",
    "user_email": "usuario@ejemplo.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "items_count": 2,
    "subtotal": "54.98",
    "updated_at": "2025-12-20T10:00:00.000Z",
    "items": [ ... ]
  }
}
```

---

### Vaciar Carrito de Usuario (Admin)
```http
DELETE /admin/carts/{userId}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "Cart cleared successfully"
}
```

---

### Estadísticas de Carritos (Admin)
```http
GET /admin/carts-stats
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "stats": {
    "total_carts": 10,
    "total_items": 25,
    "total_value": "1245.50",
    "average_cart_value": "124.55",
    "carts_with_items": 8
  }
}
```

---

## 📦 Gestión de Pedidos (Admin)

### Listar Todos los Pedidos (Admin)
```http
GET /admin/orders?page=1&limit=20&status=pending
Authorization: Bearer {token}
```

**Parámetros de Query:**
- `page` (opcional): Número de página (por defecto: 1)
- `limit` (opcional): Pedidos por página (por defecto: 20)
- `status` (opcional): Filtrar por estado (`pending`, `confirmed`, `processing`, `shipped`, `delivered`, `cancelled`)

**Respuesta:**
```json
{
  "orders": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "order_number": "ORD-1234567890-ABC123",
      "status": "confirmed",
      "subtotal": "84.97",
      "tax": "8.50",
      "shipping": "5.00",
      "total": "98.47",
      "payment_status": "paid",
      "payment_method": "credit_card",
      "shipping_address": {
        "street": "Calle Principal 123",
        "city": "Madrid",
        "state": "Madrid",
        "zipCode": "28001",
        "country": "España"
      },
      "user_email": "usuario@ejemplo.com",
      "user_first_name": "Juan",
      "user_last_name": "Pérez",
      "items_count": 2,
      "created_at": "2025-12-20T10:00:00.000Z",
      "updated_at": "2025-12-20T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalItems": 15,
    "totalPages": 1
  }
}
```

**Nota:** Incluye información del usuario que realizó el pedido.

---

### Obtener Detalle de Pedido (Admin)
```http
GET /admin/orders/{orderId}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "order": {
    "id": "uuid",
    "user_id": "uuid",
    "order_number": "ORD-1234567890-ABC123",
    "status": "confirmed",
    "subtotal": "84.97",
    "tax": "8.50",
    "shipping": "5.00",
    "total": "98.47",
    "payment_status": "paid",
    "payment_method": "credit_card",
    "shipping_address": { ... },
    "user_email": "usuario@ejemplo.com",
    "user_first_name": "Juan",
    "user_last_name": "Pérez",
    "created_at": "2025-12-20T10:00:00.000Z",
    "updated_at": "2025-12-20T10:00:00.000Z",
    "items": [
      {
        "id": "uuid",
        "product_id": "uuid",
        "product_name": "Tutorial de Flutter Completo",
        "product_description": "Aprende Flutter desde cero",
        "quantity": 2,
        "unit_price": 29.99,
        "subtotal": 59.98,
        "youtube_thumbnail": "https://i.ytimg.com/vi/..."
      },
      {
        "id": "uuid",
        "product_id": "uuid",
        "product_name": "React.js para Principiantes",
        "product_description": "Guía completa para empezar con React.js",
        "quantity": 1,
        "unit_price": 24.99,
        "subtotal": 24.99,
        "youtube_thumbnail": "https://i.ytimg.com/vi/..."
      }
    ]
  }
}
```

---

### Cancelar Pedido (Admin)
```http
DELETE /admin/orders/{orderId}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "Order cancelled successfully"
}
```

**Nota:** Solo se pueden cancelar pedidos en estado `pending` o `confirmed`.

---

## 🏥 Health Check

### Verificar Estado del API
```http
GET /health
```

**Respuesta:**
```json
{
  "status": "ok",
  "timestamp": "2025-12-20T10:00:00.000Z"
}
```

---

## 📝 Notas Importantes

### Autenticación
- Todos los endpoints marcados como **(Protegido)** requieren el header:
  ```
  Authorization: Bearer {token}
  ```
- El token se obtiene al hacer login o registro
- El token expira en 7 días (configurable)

### Roles de Usuario
- `user`: Usuario regular (no puede acceder al portal administrativo)
- `admin`: Administrador (acceso completo al portal y endpoints administrativos)
- `superadmin`: Super administrador (`julioleon2004@gmail.com`, no puede ser eliminado)

### Control de Acceso
**Portal Administrativo:**
- ✅ Permitido: usuarios con rol `admin` o `superadmin`
- ❌ Bloqueado: usuarios con rol `user` u otros roles

**Endpoints Administrativos:**
Los siguientes prefijos requieren rol `admin` o `superadmin`:
- `/api/users` - Gestión de usuarios
- `/api/admin/carts` - Gestión de carritos
- `/api/admin/orders` - Gestión de pedidos
- `/api/products` (POST, PUT, DELETE) - CRUD de productos
- `/api/youtube` - Búsqueda de videos

**Endpoints Públicos:**
- `/api/auth/login` - Inicio de sesión
- `/api/auth/register` - Registro
- `/api/products` (GET) - Listar productos
- `/api/categories` (GET) - Listar categorías
- `/api/health` - Estado del servidor

### Códigos de Estado HTTP
- `200` - OK
- `201` - Created
- `400` - Bad Request (error de validación)
- `401` - Unauthorized (sin autenticación o token inválido)
- `403` - Forbidden (sin permisos de administrador)
- `404` - Not Found
- `409` - Conflict (recurso duplicado)
- `500` - Internal Server Error

### Formato de Errores

**Errores de Validación (400):**
```json
{
  "errors": [
    {
      "type": "field",
      "value": "r@r.c",
      "msg": "Debe proporcionar un email válido",
      "path": "email",
      "location": "body"
    }
  ]
}
```

**Errores Generales (401, 403, 404, 500):**
```json
{
  "error": {
    "message": "Invalid credentials",
    "status": 401
  }
}
```

**Mensajes de Validación Personalizados:**
- Email inválido: `"Debe proporcionar un email válido"`
- Contraseña requerida: `"La contraseña es requerida"`
- Credenciales incorrectas: `"Invalid credentials"`
- Cuenta desactivada: `"Account is deactivated"`
- Sin permisos de admin: `"Access denied. Admin privileges required."`

### Paginación
Los endpoints de listado soportan paginación:
- Por defecto: `page=1`, `limit=10`
- Límite máximo: `limit=100`

### Estados de Pedido
- `pending` - Pendiente
- `confirmed` - Confirmado (después del pago)
- `processing` - En proceso
- `shipped` - Enviado
- `delivered` - Entregado
- `cancelled` - Cancelado

### Estados de Pago
- `pending` - Pendiente
- `paid` - Pagado
- `failed` - Fallido
- `refunded` - Reembolsado

### Categorías Automáticas
- Las categorías se crean automáticamente basándose en los canales de YouTube
- Cada canal de YouTube genera su propia categoría
- Las categorías se reutilizan para videos del mismo canal

### YouTube API
- Requiere configurar `YOUTUBE_API_KEY` en el archivo `.env`
- Consultar `YOUTUBE_API_KEY_GUIDE.md` para instrucciones de configuración
- Cuota diaria gratuita: 10,000 unidades
- Búsqueda: 100 unidades por llamada

---

## 🔑 Credenciales de Prueba

### Usuario Administrador
```
Email: test@ejemplo.com
Password: Test123!
Rol: admin
```

### Usuario Super Administrador
```
Email: julioleon2004@gmail.com
Password: Admin123!
Rol: superadmin
Nota: Este usuario NO puede ser eliminado
```

---

## 📚 Documentación Adicional

- **Guía de YouTube API:** `docs/YOUTUBE_API_KEY_GUIDE.md`
- **Guía de Adminer:** `docs/ADMINER_GUIDE.md`
- **Estado Actual:** `docs/ESTADO_ACTUAL.md`
- **Implementación Completa:** `docs/IMPLEMENTACION_COMPLETADA_backend.md`

