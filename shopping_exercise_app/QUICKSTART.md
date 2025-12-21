# GUÍA RÁPIDA - Shopping Exercise App Flutter

## 🚀 Inicio Rápido

### 1. Prerequisitos
```bash
✓ Flutter SDK 3.10.4+
✓ Android Studio / VS Code
✓ Backend corriendo en localhost:3000
```

### 2. Instalación
```bash
cd shopping_exercise_app
flutter pub get
flutter run
```

### 3. Credenciales
La app se autentica automáticamente con:
- **Email**: user@ejemplo.com
- **Password**: User123!

## 📱 Funcionalidades Principales

### Explorar Videos
1. Abre la app → Ver catálogo de videos
2. Usa la barra de búsqueda para buscar
3. Filtra por categorías (canales de YouTube)
4. Scroll infinito para más productos

### Ver Detalle
1. Toca cualquier video del catálogo
2. Ve información completa
3. Toca el botón de play para abrir en YouTube
4. Ajusta la cantidad y agrega al carrito

### Carrito de Compras
1. Toca el ícono del carrito en el AppBar
2. Modifica cantidades con + / -
3. Elimina productos con el ícono de basura
4. Procede al pago con el botón inferior

### Realizar Compra
1. Completa el formulario de dirección
2. Selecciona método de pago
3. Revisa el resumen (subtotal, IVA, envío)
4. Toca "Pagar" para simular el pago
5. El backend responde con éxito/fallo (90% éxito)

### Ver Órdenes
1. Toca "Pedidos" en el bottom navigation
2. Ve todas tus órdenes con estados
3. Toca cualquier orden para ver detalles
4. Revisa productos, dirección y costos

## 🎨 Características del Diseño

### Colores
- **Primario**: Azul Marino (#0A1931)
- **Secundario**: Dorado (#FFD700)
- **Superficie**: Blanco
- **Error**: Rojo (#E74C3C)
- **Éxito**: Verde (#27AE60)

### Componentes
- Cards con sombras suaves
- Botones dorados con texto azul
- AppBar azul marino
- Chips para categorías y estados
- Loading indicators dorados

## 🔧 Configuración

### Cambiar URL del Backend
Edita `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://TU_IP:3000/api';
```

### Para Android (emulador)
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

### Para iOS (simulador)
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### Para dispositivo físico
```dart
static const String baseUrl = 'http://192.168.X.X:3000/api';
```

## 📊 Estructura de Datos

### Producto
- ID, nombre, descripción
- Precio, precio con descuento
- Stock disponible
- Video ID de YouTube
- Thumbnail, duración
- Categoría (canal)

### Orden
- Número de orden único
- Estados: pending, confirmed, processing, shipped, delivered, cancelled
- Pago: pending, paid, failed, refunded
- Subtotal, IVA, envío, total
- Dirección de envío
- Lista de productos

## 🐛 Troubleshooting

### Error de conexión
```
✗ Error de conexión
→ Verifica que el backend esté corriendo
→ Revisa la URL en api_config.dart
→ Asegúrate de que no haya firewall bloqueando
```

### No carga productos
```
✗ Lista vacía o error 401
→ Verifica que el usuario público exista en la BD
→ Ejecuta: docker-compose exec api node add_public_user.js
→ Reinicia la app
```

### Imágenes no cargan
```
✗ Thumbnails en blanco
→ Verifica conexión a internet
→ Las URLs de YouTube deben ser válidas
→ Revisa permisos de internet en Android
```

### Pago no funciona
```
✗ Error al procesar pago
→ Verifica que el backend tenga el endpoint /orders/:id/pay
→ Revisa logs del backend para más detalles
→ El backend simula 90% éxito, 10% fallo
```

## 💡 Tips de Desarrollo

### Hot Reload
```bash
r  # Hot reload (preserva el estado)
R  # Hot restart (reinicia la app)
q  # Quit
```

### Debug
```bash
flutter run --debug          # Modo debug (más lento)
flutter run --profile        # Modo profile (para performance)
flutter run --release        # Modo release (producción)
```

### Logs
```bash
flutter logs                 # Ver logs en tiempo real
```

### Limpiar cache
```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Build para Producción

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Luego usar Xcode para archivar y subir
```

## 🎯 Testing Checklist

- [ ] Catálogo carga productos
- [ ] Búsqueda funciona
- [ ] Filtros por categoría
- [ ] Agregar al carrito
- [ ] Modificar cantidades en carrito
- [ ] Eliminar del carrito
- [ ] Proceso de checkout completo
- [ ] Simulación de pago (éxito)
- [ ] Simulación de pago (fallo)
- [ ] Ver lista de órdenes
- [ ] Ver detalle de orden
- [ ] Abrir video en YouTube

## 📞 Soporte

Para problemas o dudas:
1. Revisa `shopping_exercise_app/README.md`
2. Revisa `docs/APP_FLUTTER_COMPLETADA.md`
3. Revisa los logs: `flutter logs`
4. Revisa el código en `lib/`

## 🎉 ¡Listo!

La app está completamente funcional. Disfruta explorando y comprando videos! 🚀

