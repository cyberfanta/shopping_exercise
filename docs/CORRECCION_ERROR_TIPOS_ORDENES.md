# Corrección: Error de Tipo en Órdenes

## 🐛 Problema Reportado

Después de realizar una compra, al entrar en la pantalla de órdenes aparecía:
```
TypeError: "1" (string) is not a subtype of int?
```

## 🔍 Causa del Error

PostgreSQL devuelve algunos campos numéricos como **strings** en ciertas consultas:

### Campos Afectados:
1. **`items_count`** - Resultado de `COUNT()` en SQL
2. **`quantity`** - Puede venir como string dependiendo del driver

### Ejemplo de Respuesta del Backend:
```json
{
  "orders": [
    {
      "id": "uuid",
      "items_count": "2",  // ❌ String en lugar de int
      "items": [
        {
          "quantity": "1",   // ❌ String en lugar de int
          ...
        }
      ]
    }
  ]
}
```

### Error en el Modelo (ANTES):
```dart
// lib/models/order.dart
factory Order.fromJson(Map<String, dynamic> json) {
  return Order(
    // ...
    itemsCount: json['items_count'] as int?,  // ❌ Crash si es string
  );
}

// lib/models/order.dart
factory OrderItem.fromJson(Map<String, dynamic> json) {
  return OrderItem(
    // ...
    quantity: json['quantity'] as int,  // ❌ Crash si es string
  );
}
```

## ✅ Solución Aplicada

Actualicé todos los parsers para manejar tanto `int` como `String`:

### 1. Archivo: `lib/models/order.dart`

#### Order.fromJson - Campo `items_count`:
```dart
itemsCount: json['items_count'] != null
    ? (json['items_count'] is String
        ? int.parse(json['items_count'] as String)  // Parse si es string
        : json['items_count'] as int)               // Cast si es int
    : null,
```

#### OrderItem.fromJson - Campo `quantity`:
```dart
quantity: json['quantity'] is String
    ? int.parse(json['quantity'] as String)  // Parse si es string
    : json['quantity'] as int,               // Cast si es int
```

### 2. Archivo: `lib/models/cart.dart`

#### CartItem.fromJson - Campo `quantity`:
```dart
quantity: json['quantity'] is String
    ? int.parse(json['quantity'] as String)  // Parse si es string
    : json['quantity'] as int,               // Cast si es int
```

## 📋 Resumen de Cambios

| Archivo | Modelo | Campo | Antes | Ahora |
|---------|--------|-------|-------|-------|
| `lib/models/order.dart` | `Order` | `itemsCount` | `as int?` | Parser flexible int/String |
| `lib/models/order.dart` | `OrderItem` | `quantity` | `as int` | Parser flexible int/String |
| `lib/models/cart.dart` | `CartItem` | `quantity` | `as int` | Parser flexible int/String |

## 🎯 Resultado

- ✅ **Pantalla de órdenes se carga** sin errores
- ✅ **Muestra correctamente** el número de items
- ✅ **Detalle de orden funciona** correctamente
- ✅ **Items en el carrito** se muestran con cantidades correctas
- ✅ **Funciona tanto si el backend** envía int o string

## 🧪 Cómo Probar

1. **Realiza una compra:**
   - Agrega productos al carrito
   - Completa el checkout
   - Simula el pago

2. **Ve a la pantalla de órdenes:**
   - Toca "Pedidos" en el bottom navigation
   - ✅ Deberías ver tus órdenes sin errores
   - ✅ Cada orden muestra el número de items

3. **Abre el detalle de una orden:**
   - Toca cualquier orden
   - ✅ Deberías ver los productos con sus cantidades
   - ✅ Sin errores de tipo

## 🔄 Patrón de Parsing Defensivo

Este patrón ahora se usa consistentemente en todos los modelos:

### Para números enteros:
```dart
// Acepta int o String
quantity: json['quantity'] is String
    ? int.parse(json['quantity'] as String)
    : json['quantity'] as int,
```

### Para números decimales:
```dart
// Acepta double, num o String
price: (json['price'] is String)
    ? double.parse(json['price'] as String)
    : (json['price'] as num).toDouble(),
```

### Para números opcionales:
```dart
// Acepta int, String o null
itemsCount: json['items_count'] != null
    ? (json['items_count'] is String
        ? int.parse(json['items_count'] as String)
        : json['items_count'] as int)
    : null,
```

## 📊 Estado de los Modelos

| Modelo | Campos Numéricos | Estado |
|--------|------------------|--------|
| `Product` | `price`, `stock` | ✅ Ya manejaba String |
| `Cart` | `subtotal/total` | ✅ Ya manejaba String |
| `CartItem` | `quantity`, `price`, `subtotal` | ✅ Corregido |
| `Order` | `subtotal`, `tax`, `shipping`, `total`, `itemsCount` | ✅ Corregido |
| `OrderItem` | `quantity`, `unitPrice`, `subtotal` | ✅ Corregido |

## ✅ Verificación

**Todos los modelos ahora manejan correctamente:**
- ✅ Números como `int` o `double`
- ✅ Números como `String` (del backend)
- ✅ Campos opcionales (`null`)

**La app funciona con cualquier formato que envíe el backend.**

---

**Fecha:** Diciembre 21, 2025  
**Estado:** ✅ CORREGIDO  
**Archivos modificados:** 2  
**Modelos actualizados:** 3 (Order, OrderItem, CartItem)

