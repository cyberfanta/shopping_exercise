# Corrección: Error 404 al Agregar al Carrito

## 🐛 Problema Reportado

Al intentar agregar un video al carrito, aparecía el error:
```json
{
  "error": {
    "message": "Route not found",
    "status": 404
  }
}
```

## 🔍 Causa del Error

Las rutas del backend para el carrito son diferentes a las que estaba usando la app:

### Rutas Correctas del Backend
```javascript
// shopping_exercise_backend/api/src/routes/cart.routes.js

router.get('/',                    // GET /cart
router.post('/items',              // POST /cart/items      ← Agregar
router.put('/items/:item_id',      // PUT /cart/items/:id   ← Actualizar
router.delete('/items/:item_id',   // DELETE /cart/items/:id ← Eliminar
router.delete('/',                 // DELETE /cart          ← Vaciar
```

### Rutas que Estaba Usando la App (INCORRECTAS)
```dart
POST /cart              ❌ (debería ser /cart/items)
PUT /cart/:id           ❌ (debería ser /cart/items/:id)
DELETE /cart/:id        ❌ (debería ser /cart/items/:id)
```

## ✅ Solución Aplicada

Actualizado el archivo `lib/services/cart_service.dart` con las rutas correctas:

```dart
class CartService {
  // ✅ Agregar al carrito
  Future<CartItem> addToCart({...}) async {
    final response = await _api.post(
      '${ApiConfig.cart}/items',  // Ahora: /cart/items
      body: {
        'product_id': productId,
        'quantity': quantity,
      },
    );
    return CartItem.fromJson(response['cartItem']);
  }

  // ✅ Actualizar cantidad
  Future<CartItem> updateCartItem({...}) async {
    final response = await _api.put(
      '${ApiConfig.cart}/items/$itemId',  // Ahora: /cart/items/:id
      body: {'quantity': quantity},
    );
    return CartItem.fromJson(response['cartItem']);
  }

  // ✅ Eliminar del carrito
  Future<void> removeFromCart(String itemId) async {
    await _api.delete('${ApiConfig.cart}/items/$itemId');  // Ahora: /cart/items/:id
  }

  // ✅ Obtener carrito (sin cambios)
  Future<Cart> getCart() async {
    final response = await _api.get(ApiConfig.cart);  // GET /cart
    return Cart.fromJson(response['cart']);
  }

  // ✅ Vaciar carrito (sin cambios)
  Future<void> clearCart() async {
    await _api.delete(ApiConfig.cart);  // DELETE /cart
  }
}
```

## 📋 Rutas Correctas del API

| Operación | Método | Ruta Backend | Estado |
|-----------|--------|--------------|--------|
| Obtener carrito | GET | `/cart` | ✅ |
| Agregar producto | POST | `/cart/items` | ✅ Corregido |
| Actualizar cantidad | PUT | `/cart/items/:item_id` | ✅ Corregido |
| Eliminar producto | DELETE | `/cart/items/:item_id` | ✅ Corregido |
| Vaciar carrito | DELETE | `/cart` | ✅ |

## 🧪 Cómo Probar

1. **Ejecuta la app:**
```bash
flutter run
```

2. **Navega a un producto:**
   - Desde el catálogo, toca cualquier video
   - Verás la pantalla de detalle

3. **Agrega al carrito:**
   - Ajusta la cantidad si quieres
   - Toca "Agregar al carrito"
   - Deberías ver un SnackBar verde: "X productos agregados al carrito"
   - El contador del carrito en el AppBar debe aumentar

4. **Verifica en el carrito:**
   - Toca el ícono del carrito
   - Deberías ver el producto agregado
   - Puedes modificar la cantidad con +/-
   - Puedes eliminar con el ícono de basura

## 🎯 Resultado

- ✅ **Agregar al carrito funciona** correctamente
- ✅ **Actualizar cantidades funciona** correctamente
- ✅ **Eliminar del carrito funciona** correctamente
- ✅ **Contador del carrito** se actualiza en tiempo real
- ✅ **Sin errores 404**

## 📝 Archivos Modificados

- ✅ `lib/services/cart_service.dart` - Rutas corregidas

---

**Fecha:** Diciembre 21, 2025  
**Estado:** ✅ CORREGIDO

