# Correcciones Aplicadas - Shopping Exercise App

## 📋 Problemas Reportados y Soluciones

### ✅ 1. Error en Carrito: "null is not a subtype of num"

**Problema:**
- El endpoint `/cart` devuelve `{"cart":{"id":"...","items":[],"total":"0.00"}}`
- El modelo `Cart` esperaba el campo `subtotal` pero el backend envía `total`

**Solución Aplicada:**
Actualizado el modelo `Cart` en `lib/models/cart.dart` para aceptar ambos campos:

```dart
factory Cart.fromJson(Map<String, dynamic> json) {
  // El backend puede devolver 'total' o 'subtotal'
  final totalValue = json['total'] ?? json['subtotal'];
  
  return Cart(
    id: json['id'] as String,
    items: (json['items'] as List<dynamic>?)
            ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [],
    subtotal: totalValue != null
        ? (totalValue is String
            ? double.parse(totalValue as String)
            : (totalValue as num).toDouble())
        : 0.0,  // Valor por defecto si es null
  );
}
```

**Resultado:**
- ✅ El carrito vacío ahora muestra correctamente subtotal = $0.00
- ✅ No más errores de tipo al parsear el JSON

---

### ✅ 2. Error en Pedidos: "null is not a subtype of Map<String,dynamic>"

**Problema:**
- El endpoint `/orders` devuelve `{"orders":[]}`
- Falta el campo `pagination` en la respuesta cuando no hay órdenes
- El código intentaba acceder a `response['pagination']` causando el error

**Solución Aplicada:**
Actualizado el servicio `OrderService` en `lib/services/order_service.dart`:

```dart
Future<Map<String, dynamic>> getOrders({...}) async {
  final response = await _api.get(...);

  final orders = (response['orders'] as List<dynamic>?)
          ?.map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList() ??
      [];

  // Manejar caso cuando no hay pagination
  final pagination = response['pagination'] as Map<String, dynamic>? ?? {
    'page': page,
    'limit': limit,
    'totalItems': 0,
    'totalPages': 0,
  };

  return {
    'orders': orders,
    'pagination': pagination,
  };
}
```

**Resultado:**
- ✅ La pantalla de órdenes vacía se muestra correctamente con el estado "Sin pedidos"
- ✅ No más errores al parsear la respuesta del backend
- ✅ Paginación funciona correctamente cuando hay órdenes

---

### ✅ 3. Botón para Login/Logout en AppBar

**Problema:**
- No había forma de cambiar de usuario
- Usuario público siempre autenticado sin opción visible de login

**Solución Aplicada:**
Agregado un **PopupMenuButton** con avatar circular en el AppBar de `HomeScreen`:

#### Características Implementadas:

1. **Avatar Circular con Menú Desplegable:**
   - Icono de persona con fondo dorado
   - Muestra el email del usuario actual
   - Diferencia visual entre usuario público y usuarios reales

2. **Para Usuario Público (user@ejemplo.com):**
   ```
   [Avatar] → PopupMenu
   ├─ Usuario Público
   │  user@ejemplo.com
   ├─ ───────────────
   └─ 🔓 Iniciar sesión
   ```

3. **Para Usuarios Reales:**
   ```
   [Avatar] → PopupMenu
   ├─ Nombre Completo
   │  email@ejemplo.com
   ├─ ───────────────
   └─ 🚪 Cerrar sesión
   ```

4. **Diálogo de Login:**
   - Formulario con email y password
   - Validación de campos
   - Muestra credenciales de prueba: `test@ejemplo.com / Test123!`
   - Loading state mientras procesa
   - Mensajes de éxito/error con SnackBars

5. **Diálogo de Logout:**
   - Confirmación antes de cerrar sesión
   - Al confirmar, cierra sesión y vuelve a usuario público automáticamente
   - Recarga el carrito y productos del nuevo usuario

#### Código Agregado:

**AppBar con Avatar:**
```dart
actions: [
  // Botón de usuario/login
  Consumer<AuthProvider>(
    builder: (context, authProvider, child) {
      final user = authProvider.user;
      final isPublicUser = user?.email == 'user@ejemplo.com';

      return PopupMenuButton<String>(
        icon: CircleAvatar(
          backgroundColor: AppTheme.gold,
          radius: 16,
          child: Icon(
            isPublicUser ? Icons.person_outline : Icons.person,
            color: AppTheme.navyBlue,
            size: 20,
          ),
        ),
        // ... menú items
      );
    },
  ),
  // ... carrito
]
```

**Métodos Agregados:**
- `_showLoginDialog()` - Muestra formulario de login
- `_showLogoutDialog()` - Confirma cierre de sesión

**Resultado:**
- ✅ Avatar circular dorado en el AppBar (antes del carrito)
- ✅ Menú desplegable con opciones según usuario
- ✅ Diálogo de login funcional con validación
- ✅ Diálogo de logout con confirmación
- ✅ Recarga automática de datos al cambiar de usuario
- ✅ Feedback visual con SnackBars

---

## 🎨 Apariencia del AppBar Actualizado

```
┌────────────────────────────────────────────┐
│ Videos Shop      [👤] [🛒3]              │
│                   ▲     ▲                  │
│                   │     └─ Carrito         │
│                   └─ Usuario/Login (NUEVO) │
└────────────────────────────────────────────┘
```

### Usuario Público:
```
Toca el avatar → 
┌─────────────────────┐
│ Usuario Público     │
│ user@ejemplo.com    │
├─────────────────────┤
│ 🔓 Iniciar sesión  │
└─────────────────────┘
```

### Usuario Logueado:
```
Toca el avatar → 
┌─────────────────────┐
│ Usuario Prueba      │
│ test@ejemplo.com    │
├─────────────────────┤
│ 🚪 Cerrar sesión   │
└─────────────────────┘
```

---

## 🔄 Flujo de Usuario

### Iniciar Sesión:
1. Usuario público ve avatar con outline
2. Toca el avatar → "Iniciar sesión"
3. Aparece diálogo con formulario
4. Ingresa credenciales (`test@ejemplo.com / Test123!`)
5. Presiona "Iniciar sesión"
6. ✅ Login exitoso → Avatar cambia a sólido
7. Carrito y productos se recargan para el nuevo usuario

### Cerrar Sesión:
1. Usuario logueado toca avatar
2. Selecciona "Cerrar sesión"
3. Aparece confirmación
4. Confirma → ✅ Sesión cerrada
5. Automáticamente vuelve a usuario público
6. Avatar vuelve a outline
7. Carrito y productos se recargan

---

## 📝 Notas Importantes

### Sobre el Usuario Público:
- **NO se muestra como "deslogueado"** porque técnicamente SÍ está logueado
- Es un usuario real con token JWT válido
- Permite acceder a endpoints protegidos del backend
- Identificado visualmente con icono outline en lugar de sólido

### Sobre el Backend:
- Los endpoints están funcionando correctamente
- El problema era de parsing en el frontend
- No requiere cambios en el backend

### Credenciales de Prueba:
```
Usuario Administrador:
- Email: test@ejemplo.com
- Password: Test123!
- Rol: admin

Usuario Público (auto-login):
- Email: user@ejemplo.com  
- Password: User123!
- Rol: user
```

---

## ✅ Resumen de Cambios

### Archivos Modificados:

1. **`lib/models/cart.dart`**
   - Manejo flexible de `total` vs `subtotal`
   - Valor por defecto para prevenir nulls

2. **`lib/services/order_service.dart`**
   - Manejo seguro de `pagination` opcional
   - Valores por defecto cuando no hay órdenes

3. **`lib/screens/home_screen.dart`**
   - Import de `AuthProvider`
   - Avatar con PopupMenuButton en AppBar
   - Método `_showLoginDialog()`
   - Método `_showLogoutDialog()`
   - Recarga de datos al cambiar usuario

---

## 🎯 Problemas Resueltos

| Problema | Estado | Solución |
|----------|--------|----------|
| Error en carrito vacío | ✅ | Parser flexible para total/subtotal |
| Error en órdenes vacías | ✅ | Pagination con valores por defecto |
| Falta botón login/logout | ✅ | Avatar con menú en AppBar |

---

## 🚀 Resultado Final

**Antes:**
- ❌ Crash al ver carrito vacío
- ❌ Crash al ver órdenes vacías
- ❌ No había forma de cambiar de usuario

**Ahora:**
- ✅ Carrito vacío se muestra correctamente
- ✅ Pantalla de órdenes vacías funciona
- ✅ Avatar en AppBar con opciones de login/logout
- ✅ Diálogos funcionales con validación
- ✅ Feedback visual apropiado
- ✅ Recarga automática de datos

**¡Todos los problemas han sido corregidos!** 🎉

---

## ✅ 4. Error 404 al Agregar al Carrito (NUEVO)

**Problema:**
- Al agregar producto al carrito aparecía: `{"error":{"message":"Route not found","status":404}}`
- Las rutas del backend son diferentes a las esperadas

**Causa:**
- Backend usa: `POST /cart/items`
- App usaba: `POST /cart` ❌

**Solución Aplicada:**
Corregidas todas las rutas en `lib/services/cart_service.dart`:

```dart
// Antes (INCORRECTO)
POST /cart              → Agregar
PUT /cart/:id           → Actualizar
DELETE /cart/:id        → Eliminar

// Ahora (CORRECTO)
POST /cart/items              → Agregar
PUT /cart/items/:id           → Actualizar
DELETE /cart/items/:id        → Eliminar
```

**Rutas Actualizadas:**
```dart
// Agregar al carrito
await _api.post('${ApiConfig.cart}/items', ...);

// Actualizar cantidad
await _api.put('${ApiConfig.cart}/items/$itemId', ...);

// Eliminar del carrito
await _api.delete('${ApiConfig.cart}/items/$itemId');
```

**Resultado:**
- ✅ Agregar al carrito funciona correctamente
- ✅ Actualizar cantidades funciona
- ✅ Eliminar del carrito funciona
- ✅ Contador del AppBar se actualiza
- ✅ Sin errores 404

---

## 📝 Resumen de Todas las Correcciones

| # | Problema | Archivo | Estado |
|---|----------|---------|--------|
| 1 | Carrito vacío (null error) | `lib/models/cart.dart` | ✅ |
| 2 | Órdenes vacías (null error) | `lib/services/order_service.dart` | ✅ |
| 3 | Falta login/logout | `lib/screens/home_screen.dart` | ✅ |
| 4 | Error 404 agregar al carrito | `lib/services/cart_service.dart` | ✅ |

**¡Todos los problemas han sido corregidos!** 🎉

