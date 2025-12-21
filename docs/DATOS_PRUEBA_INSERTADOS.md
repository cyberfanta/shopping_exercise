# ✅ Datos de Prueba Insertados Correctamente

## 📊 Resumen de Inserción

Se han agregado exitosamente **datos de prueba** a la base de datos para poder probar las funcionalidades de carritos y órdenes en el portal administrativo.

---

## 👤 Usuarios Creados

### 1. Usuario de Prueba
- **Email:** `test@ejemplo.com`
- **Password:** `Test123!`
- **Nombre:** Usuario Prueba
- **Rol:** user
- **Estado:** Activo

### 2. Superadmin (ya existía)
- **Email:** `julioleon2004@gmail.com`
- **Password:** `Admin123!`
- **Nombre:** Julio León
- **Rol:** superadmin
- **Estado:** Activo

---

## 🛒 Carritos Creados

### Carrito 1: Usuario de Prueba
**Usuario:** test@ejemplo.com  
**Items:** 2 productos

| Producto | Cantidad | Precio Unitario | Subtotal |
|----------|----------|-----------------|----------|
| Tutorial de Flutter Completo | 2 | $29.99 | $59.98 |
| React.js para Principiantes | 1 | $24.99 | $24.99 |
| **TOTAL** | **3** | - | **$84.97** |

### Carrito 2: Superadmin
**Usuario:** julioleon2004@gmail.com  
**Items:** 1 producto

| Producto | Cantidad | Precio Unitario | Subtotal |
|----------|----------|-----------------|----------|
| Node.js Backend Development | 3 | $34.99 | $104.97 |
| **TOTAL** | **3** | - | **$104.97** |

---

## 🛍️ Órdenes Creadas

### Orden 1: Usuario de Prueba
**Usuario:** test@ejemplo.com  
**Estado:** ✅ Confirmed  
**Método de Pago:** Tarjeta de crédito  
**Dirección de Envío:**
```
Calle Principal 123
San José, San José
10101, Costa Rica
```

**Desglose:**
- Subtotal: $84.97
- Impuestos (10%): $8.50
- Envío: $5.00
- **TOTAL: $98.47**

**Items:**
| Producto | Cantidad | Precio Unitario | Subtotal |
|----------|----------|-----------------|----------|
| Tutorial de Flutter Completo | 2 | $29.99 | $59.98 |
| React.js para Principiantes | 1 | $24.99 | $24.99 |

---

### Orden 2: Superadmin
**Usuario:** julioleon2004@gmail.com  
**Estado:** ⏳ Pending  
**Método de Pago:** PayPal  
**Dirección de Envío:**
```
Avenida Central 456
Heredia, Heredia
40101, Costa Rica
```

**Desglose:**
- Subtotal: $104.97
- Impuestos (10%): $10.50
- Envío: $5.00
- **TOTAL: $120.47**

**Items:**
| Producto | Cantidad | Precio Unitario | Subtotal |
|----------|----------|-----------------|----------|
| Node.js Backend Development | 3 | $34.99 | $104.97 |

---

## 📦 Productos Creados

Los siguientes productos fueron creados como parte de los datos de prueba:

### 1. Tutorial de Flutter Completo
- **ID YouTube:** dQw4w9WgXcQ
- **Precio:** $29.99
- **Stock:** 100 unidades
- **Categoría:** Canal de Prueba
- **Descripción:** Aprende Flutter desde cero hasta avanzado
- **Thumbnail:** https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg

### 2. React.js para Principiantes
- **ID YouTube:** abc123xyz
- **Precio:** $24.99
- **Stock:** 50 unidades
- **Categoría:** Canal de Prueba
- **Descripción:** Domina React.js en 5 horas
- **Thumbnail:** https://i.ytimg.com/vi/abc123xyz/hqdefault.jpg

### 3. Node.js Backend Development
- **ID YouTube:** def456uvw
- **Precio:** $34.99
- **Stock:** 75 unidades
- **Categoría:** Canal de Prueba
- **Descripción:** Crea APIs profesionales con Node.js
- **Thumbnail:** https://i.ytimg.com/vi/def456uvw/hqdefault.jpg

---

## 🔍 Verificación de Datos

### Estadísticas Insertadas:
- ✅ **2 usuarios** (1 nuevo de prueba)
- ✅ **3 productos** de prueba
- ✅ **3 carritos** activos (incluyendo uno existente del superadmin)
- ✅ **3 items** en carritos
- ✅ **2 órdenes** completadas
- ✅ **3 items** en órdenes

---

## 🚀 Cómo Probar en el Portal

### 1. Ver Carritos:
1. Inicia sesión con: `julioleon2004@gmail.com` / `Admin123!`
2. Navega a la sección **"Carrito"** en el menú lateral
3. Deberías ver **3 carritos** (2 nuevos + cualquier existente):
   - Carrito de `test@ejemplo.com` con 2 items
   - Carrito de `julioleon2004@gmail.com` con 1 item

### 2. Ver Órdenes:
1. Navega a la sección **"Pedidos"**
2. Deberías ver al menos **2 órdenes nuevas**:
   - Orden de `test@ejemplo.com` (Estado: Confirmed)
   - Orden de `julioleon2004@gmail.com` (Estado: Pending)

### 3. Ver Productos:
1. Navega a la sección **"Videos"**
2. Deberías ver **3 productos nuevos** del "Canal de Prueba"

---

## 🧪 Pruebas Recomendadas

### En la sección de Carritos:
1. ✅ Ver lista de todos los carritos
2. ✅ Click en "Ver Detalle" de un carrito
3. ✅ Click en "Vaciar" un carrito (probar con el del usuario test)
4. ✅ Verificar el contador de carritos

### En la sección de Pedidos:
1. ✅ Ver lista de todas las órdenes
2. ✅ Filtrar por estado (pending, confirmed)
3. ✅ Verificar que se muestre la info del usuario
4. ✅ Verificar el contador de órdenes

### En la sección de Videos:
1. ✅ Ver los 3 productos nuevos
2. ✅ Filtrar por "Canal de Prueba"
3. ✅ Editar precio/stock de algún producto
4. ✅ Eliminar un producto de prueba

---

## 🗑️ Limpiar Datos de Prueba (Opcional)

Si deseas eliminar los datos de prueba más adelante, ejecuta:

```sql
-- Eliminar órdenes y sus items
DELETE FROM order_items WHERE order_id IN (
    SELECT id FROM orders WHERE user_id IN (
        SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')
    )
);

DELETE FROM orders WHERE user_id IN (
    SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')
);

-- Eliminar carritos y sus items
DELETE FROM cart_items WHERE cart_id IN (
    SELECT id FROM carts WHERE user_id IN (
        SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')
    )
);

DELETE FROM carts WHERE user_id IN (
    SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')
);

-- Eliminar productos de prueba
DELETE FROM products WHERE category_id IN (
    SELECT id FROM categories WHERE name = 'Canal de Prueba'
);

-- Eliminar categoría de prueba
DELETE FROM categories WHERE name = 'Canal de Prueba';

-- Eliminar usuario de prueba (NO eliminar el superadmin)
DELETE FROM users WHERE email = 'test@ejemplo.com';
```

---

## 📝 Notas Importantes

1. **Usuario de Prueba:**
   - Puedes iniciar sesión con `test@ejemplo.com` / `Test123!` para ver la experiencia desde el lado del usuario (aunque esto es un portal admin)

2. **Carritos:**
   - Los carritos se actualizan automáticamente cuando se agregan/quitan items
   - Solo se muestran carritos con al menos 1 item

3. **Órdenes:**
   - Las órdenes tienen diferentes estados: pending, confirmed, shipped, delivered, cancelled
   - Los números de orden se generan automáticamente

4. **Productos:**
   - Los thumbnails de YouTube pueden no cargar si los IDs no son válidos
   - Los productos están activos por defecto

---

## ✅ Estado Actual

El sistema ahora tiene:
- ✅ Datos de prueba completos para carritos y órdenes
- ✅ Backend funcionando correctamente
- ✅ Frontend listo para mostrar los datos
- ✅ Todas las funcionalidades probables

**¡Listo para probar el portal administrativo completo!** 🎉

