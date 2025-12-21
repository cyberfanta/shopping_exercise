# 🎯 Portal Administrativo - Estado Actual

## 📊 Secciones del Portal

### 1. 📹 Videos de YouTube ✅ FUNCIONAL
**Propósito:** Gestión del catálogo de videos
- ✅ Ver todos los videos del catálogo
- ✅ Buscar y agregar videos desde YouTube
- ✅ Editar precios y stock
- ✅ Eliminar videos
- ✅ Filtrar por canal
- ✅ Infinite scroll
- ✅ Contador visible

---

### 2. 🛒 Carritos de Usuarios ⚠️ PENDIENTE
**Propósito:** Vista administrativa de todos los carritos de compra

**Estado:** Vista creada pero requiere endpoint del backend

**Lo que debería mostrar:**
- Lista de todos los usuarios que tienen items en su carrito
- Items en cada carrito
- Cantidades y precios
- Subtotal por usuario
- Última actualización del carrito
- Opción para ver detalles o vaciar carrito de un usuario

**Endpoint requerido:**
```
GET /api/admin/carts?page=1&limit=20
```

**Respuesta esperada:**
```json
{
  "carts": [
    {
      "user_id": "uuid",
      "user_email": "usuario@ejemplo.com",
      "user_name": "Juan Pérez",
      "items_count": 3,
      "subtotal": "45.99",
      "updated_at": "2025-12-20T10:30:00Z",
      "items": [
        {
          "product_id": "uuid",
          "product_name": "Video Tutorial",
          "price": "15.99",
          "quantity": 2,
          "subtotal": "31.98"
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "totalItems": 45,
    "totalPages": 3
  }
}
```

---

### 3. 🛍️ Pedidos ✅ FUNCIONAL
**Propósito:** Ver todos los pedidos de todos los usuarios

**Estado:** Completamente funcional

**Características actuales:**
- ✅ Lista de todos los pedidos del sistema
- ✅ Filtro por estado
- ✅ Ver número de orden, fecha, total
- ✅ Ver cantidad de items por pedido
- ✅ Cancelar pedidos
- ✅ Infinite scroll
- ✅ Contador visible
- ✅ Colores por estado

**Mejora sugerida:** Agregar columna de usuario para saber quién hizo cada pedido

---

### 4. 👥 Usuarios ✅ FUNCIONAL
**Propósito:** Gestión de usuarios del sistema

**Estado:** Completamente funcional

**Características:**
- ✅ Lista de todos los usuarios
- ✅ Editar roles (user, admin)
- ✅ Activar/desactivar cuentas
- ✅ Protección del superadmin
- ✅ Filtrar por rol
- ✅ Buscar por nombre/email
- ✅ Infinite scroll
- ✅ Contador visible

---

## 🔧 Pendientes de Backend

### 1. Endpoint de Carritos Administrativo
**Archivo a crear:** `shopping_exercise_backend/api/src/routes/admin.routes.js`

**Endpoints necesarios:**
```javascript
// Listar todos los carritos con paginación
GET /api/admin/carts?page=1&limit=20

// Ver detalle de un carrito específico
GET /api/admin/carts/:userId

// Vaciar carrito de un usuario
DELETE /api/admin/carts/:userId

// Estadísticas de carritos
GET /api/admin/carts/stats
```

**Controller a crear:** `shopping_exercise_backend/api/src/controllers/admin.controller.js`

**Queries SQL necesarias:**
```sql
-- Obtener todos los carritos activos
SELECT 
  c.user_id,
  u.email,
  u.first_name,
  u.last_name,
  COUNT(ci.id) as items_count,
  SUM(ci.quantity * ci.price) as subtotal,
  c.updated_at
FROM carts c
JOIN users u ON c.user_id = u.id
LEFT JOIN cart_items ci ON c.id = ci.cart_id
GROUP BY c.id, c.user_id, u.email, u.first_name, u.last_name
HAVING COUNT(ci.id) > 0
ORDER BY c.updated_at DESC
LIMIT 20 OFFSET 0;
```

---

### 2. Mejorar Endpoint de Pedidos
**Archivo a modificar:** `shopping_exercise_backend/api/src/controllers/order.controller.js`

**Agregar información del usuario:**
```javascript
// Modificar query para incluir datos del usuario
SELECT 
  o.*,
  u.email as user_email,
  u.first_name as user_first_name,
  u.last_name as user_last_name,
  COUNT(oi.id) as items_count
FROM orders o
JOIN users u ON o.user_id = u.id
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, u.email, u.first_name, u.last_name
ORDER BY o.created_at DESC;
```

**Actualizar modelo Order.dart:**
```dart
class Order {
  // ... campos existentes
  final String? userEmail;
  final String? userName;
  // ...
}
```

---

## 📋 Funcionalidades del Portal Administrativo

### Lo que DEBE hacer el portal:
✅ Ver y gestionar el catálogo de videos (productos)  
⚠️ Monitorear carritos de todos los usuarios  
✅ Ver todos los pedidos del sistema  
✅ Gestionar usuarios y roles  
❌ Estadísticas generales (dashboard con métricas)  
❌ Reportes de ventas  

### Lo que NO debe hacer:
❌ Comprar productos (eso lo hacen los usuarios finales)  
❌ Agregar items a un carrito específico  
❌ Hacer checkout  

---

## 🎨 UX del Portal Administrativo

### Vista de Carritos (cuando se implemente):
```
┌────────────────────────────────────────────────────┐
│ Carritos de Usuarios                    🔄  15 / 45│
├────────────────────────────────────────────────────┤
│                                                    │
│ ┌────────────────────────────────────────────┐   │
│ │ 👤 Juan Pérez (juan@ejemplo.com)           │   │
│ │ 🛒 3 items • $45.99                        │   │
│ │ ⏰ Actualizado: hace 2 horas                │   │
│ │                                             │   │
│ │ • Video Tutorial 1 (2x) - $31.98          │   │
│ │ • Video Tutorial 2 (1x) - $13.99          │   │
│ │                                             │   │
│ │ [Ver Detalle] [Vaciar Carrito]            │   │
│ └────────────────────────────────────────────┘   │
│                                                    │
│ ┌────────────────────────────────────────────┐   │
│ │ 👤 María García (maria@ejemplo.com)        │   │
│ │ 🛒 1 item • $29.99                         │   │
│ │ ⏰ Actualizado: hace 5 minutos              │   │
│ │                                             │   │
│ │ • Video Premium (1x) - $29.99              │   │
│ │                                             │   │
│ │ [Ver Detalle] [Vaciar Carrito]            │   │
│ └────────────────────────────────────────────┘   │
│                                                    │
│ [Cargar más carritos...]                          │
└────────────────────────────────────────────────────┘
```

### Vista de Pedidos (mejorada con usuario):
```
┌────────────────────────────────────────────────────┐
│ Pedidos de Todos los Usuarios          🔄  25 / 150│
├────────────────────────────────────────────────────┤
│ Filtrar: [Todos los estados ▼]                    │
├────────────────────────────────────────────────────┤
│                                                    │
│ ┌────────────────────────────────────────────┐   │
│ │ ORD-1234567890-ABC123      [CONFIRMADO]    │   │
│ │ 👤 Juan Pérez (juan@ejemplo.com)           │   │
│ │ 📅 20/12/2025 14:30                        │   │
│ │ 🛒 3 items • Total: $150.75                │   │
│ │ 💳 Tarjeta de crédito                      │   │
│ └────────────────────────────────────────────┘   │
│                                                    │
└────────────────────────────────────────────────────┘
```

---

## 🚀 Siguiente Paso

### Opción 1: Implementar Backend de Carritos Admin
1. Crear `admin.routes.js`
2. Crear `admin.controller.js`
3. Implementar queries SQL
4. Agregar middleware de admin
5. Actualizar frontend con los datos reales

### Opción 2: Mejorar Vista de Pedidos
1. Agregar info de usuario en el backend
2. Actualizar modelo Order en Flutter
3. Mostrar usuario en cada tarjeta de pedido

### Opción 3: Dashboard con Estadísticas
1. Crear página de Dashboard con métricas
2. Mostrar:
   - Total de ventas del día/mes
   - Pedidos pendientes
   - Carritos abandonados
   - Videos más vendidos
   - Gráficas

---

## 📝 Resumen

**Estado actual:**
- ✅ 2 de 4 secciones completamente funcionales (Videos, Usuarios)
- ✅ 1 sección funcional pero mejorable (Pedidos - falta info de usuario)
- ⚠️ 1 sección pendiente de backend (Carritos)

**Prioridad:**
1. Implementar endpoint de carritos admin
2. Agregar info de usuario en pedidos
3. Crear dashboard con estadísticas

¿Quieres que implemente el endpoint de carritos en el backend? 🚀

