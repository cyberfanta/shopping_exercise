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
    "is_active": true
  },
  "token": "jwt_token_here"
}
```

---

### Solicitar Restablecimiento de Contraseña
```http
POST /auth/forgot-password
Content-Type: application/json

{
  "email": "usuario@ejemplo.com"
}
```

**Respuesta:**
```json
{
  "message": "If the email exists, a reset link has been sent"
}
```

---

### Restablecer Contraseña
```http
POST /auth/reset-password
Content-Type: application/json

{
  "token": "reset_token_from_email",
  "password": "new_password123"
}
```

**Respuesta:**
```json
{
  "message": "Password reset successfully"
}
```

---

### Obtener Usuario Actual (Protegido)
```http
GET /auth/me
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "user": {
    "id": "uuid",
    "email": "usuario@ejemplo.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "phone": "+34612345678",
    "created_at": "2025-12-20T10:00:00.000Z"
  }
}
```

---

### Actualizar Perfil (Protegido)
```http
PUT /auth/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "first_name": "Juan Carlos",
  "last_name": "Pérez García",
  "phone": "+34612345679"
}
```

---

### Cambiar Contraseña (Protegido)
```http
POST /auth/change-password
Authorization: Bearer {token}
Content-Type: application/json

{
  "current_password": "old_password123",
  "new_password": "new_password456"
}
```

---

## 📦 Productos

### Obtener Todos los Productos
```http
GET /products?page=1&limit=10&category_id={uuid}&search=laptop
```

**Parámetros de consulta:**
- `page` (opcional): Número de página (default: 1)
- `limit` (opcional): Elementos por página (default: 10, max: 100)
- `category_id` (opcional): Filtrar por categoría
- `search` (opcional): Buscar por nombre o descripción

**Respuesta:**
```json
{
  "products": [
    {
      "id": "uuid",
      "category_id": "uuid",
      "category_name": "Electrónica",
      "name": "Laptop Pro 15\"",
      "description": "Laptop de alto rendimiento",
      "price": "1299.99",
      "discount_price": null,
      "stock": 10,
      "image_url": null,
      "images": [],
      "is_active": true,
      "created_at": "2025-12-20T10:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "totalItems": 50,
    "totalPages": 5
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
    "category_id": "uuid",
    "category_name": "Electrónica",
    "name": "Laptop Pro 15\"",
    "description": "Laptop de alto rendimiento",
    "price": "1299.99",
    "stock": 10,
    "image_url": null,
    "is_active": true
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
  "name": "Nuevo Producto",
  "description": "Descripción del producto",
  "price": 99.99,
  "stock": 50,
  "category_id": "uuid",
  "image_url": "https://example.com/image.jpg"
}
```

---

### Actualizar Producto (Protegido)
```http
PUT /products/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Nombre Actualizado",
  "price": 89.99,
  "stock": 45
}
```

---

### Eliminar Producto (Protegido)
```http
DELETE /products/{id}
Authorization: Bearer {token}
```

---

## 🗂️ Categorías

### Obtener Todas las Categorías
```http
GET /categories
```

**Respuesta:**
```json
{
  "categories": [
    {
      "id": "uuid",
      "name": "Electrónica",
      "description": "Dispositivos electrónicos",
      "image_url": null,
      "is_active": true
    }
  ]
}
```

---

### Obtener Categoría por ID
```http
GET /categories/{id}
```

---

### Crear Categoría (Protegido)
```http
POST /categories
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Nueva Categoría",
  "description": "Descripción de la categoría"
}
```

---

### Actualizar Categoría (Protegido)
```http
PUT /categories/{id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Categoría Actualizada",
  "description": "Nueva descripción"
}
```

---

### Eliminar Categoría (Protegido)
```http
DELETE /categories/{id}
Authorization: Bearer {token}
```

---

## 🛒 Carrito de Compras

### Obtener Carrito (Protegido)
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
        "quantity": 2,
        "price": "1299.99",
        "subtotal": "2599.98",
        "product_id": "uuid",
        "product_name": "Laptop Pro 15\"",
        "product_description": "Laptop de alto rendimiento",
        "image_url": null,
        "stock": 10
      }
    ],
    "total": "2599.98"
  }
}
```

---

### Añadir Producto al Carrito (Protegido)
```http
POST /cart/items
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
  "message": "Item added to cart successfully"
}
```

---

### Actualizar Cantidad de Item (Protegido)
```http
PUT /cart/items/{item_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "quantity": 3
}
```

---

### Eliminar Item del Carrito (Protegido)
```http
DELETE /cart/items/{item_id}
Authorization: Bearer {token}
```

---

### Vaciar Carrito (Protegido)
```http
DELETE /cart
Authorization: Bearer {token}
```

---

## 📋 Órdenes / Pedidos

### Obtener Pedidos del Usuario (Protegido)
```http
GET /orders
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "orders": [
    {
      "id": "uuid",
      "order_number": "ORD-1234567890-ABC123",
      "status": "pending",
      "subtotal": "2599.98",
      "tax": "415.99",
      "shipping": "50.00",
      "total": "3065.97",
      "payment_status": "pending",
      "payment_method": "credit_card",
      "shipping_address": {
        "street": "Calle Principal 123",
        "city": "Madrid",
        "state": "Madrid",
        "zip": "28001",
        "country": "España"
      },
      "items_count": 2,
      "created_at": "2025-12-20T10:00:00.000Z"
    }
  ]
}
```

---

### Obtener Pedido por ID (Protegido)
```http
GET /orders/{id}
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "order": {
    "id": "uuid",
    "order_number": "ORD-1234567890-ABC123",
    "status": "pending",
    "subtotal": "2599.98",
    "tax": "415.99",
    "shipping": "50.00",
    "total": "3065.97",
    "payment_status": "pending",
    "payment_method": "credit_card",
    "shipping_address": {...},
    "items": [
      {
        "id": "uuid",
        "product_id": "uuid",
        "product_name": "Laptop Pro 15\"",
        "quantity": 2,
        "unit_price": "1299.99",
        "subtotal": "2599.98"
      }
    ],
    "created_at": "2025-12-20T10:00:00.000Z"
  }
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

### Simular Pago (Protegido) - Solo desarrollo
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

**Respuesta (Fallo):**
```json
{
  "error": {
    "message": "Payment failed. Please try again.",
    "status": 400
  }
}
```

---

### Cancelar Pedido (Protegido)
```http
POST /orders/{id}/cancel
Authorization: Bearer {token}
```

**Respuesta:**
```json
{
  "message": "Order cancelled successfully"
}
```

**Notas:**
- El stock de productos se restaurará automáticamente
- No se pueden cancelar pedidos ya enviados o entregados

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

### Códigos de Estado HTTP
- `200` - OK
- `201` - Created
- `400` - Bad Request (error de validación)
- `401` - Unauthorized (sin autenticación o token inválido)
- `403` - Forbidden (sin permisos)
- `404` - Not Found
- `409` - Conflict (recurso duplicado)
- `500` - Internal Server Error

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

