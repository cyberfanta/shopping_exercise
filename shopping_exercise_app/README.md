# Shopping Exercise App - Flutter

Aplicación móvil de compra de videos de YouTube desarrollada en Flutter.

## Descripción

Esta aplicación permite a los usuarios navegar, buscar y comprar videos de YouTube. Es un ejercicio de desarrollo que implementa un sistema completo de e-commerce con autenticación, gestión de carrito, procesamiento de pagos simulado y gestión de órdenes.

## Características

### 🎨 Diseño
- **Tema personalizado** con colores azul marino (#0A1931) y dorado (#FFD700)
- **Material Design 3** con componentes modernos
- **Responsive** con enfoque en orientación vertical
- **Interfaz intuitiva** y fácil de usar

### 🔐 Autenticación
- Login automático con usuario público (user@ejemplo.com)
- Sistema de autenticación con JWT tokens
- Sesión persistente con SharedPreferences

### 📱 Funcionalidades Principales

#### 1. Catálogo de Productos
- **Listado paginado** de videos con scroll infinito
- **Búsqueda en tiempo real** por nombre y descripción
- **Filtros por categoría** (basadas en canales de YouTube)
- **Tarjetas de producto** con:
  - Thumbnail del video
  - Duración del video
  - Precio y descuentos
  - Botón de agregar al carrito

#### 2. Detalle de Producto
- Información completa del video
- Reproducción en YouTube (abre la app)
- Selector de cantidad
- Agregar al carrito con cantidad personalizada

#### 3. Carrito de Compras
- **Gestión completa del carrito**:
  - Agregar productos
  - Modificar cantidades
  - Eliminar productos
  - Vaciar carrito
- **Resumen en tiempo real**:
  - Subtotal
  - IVA (16%)
  - Información de envío

#### 4. Proceso de Compra (Checkout)
- **Formulario de dirección de envío**
- **Selección de método de pago**:
  - Tarjeta de crédito
  - Tarjeta de débito
  - PayPal
- **Simulación de pago** con el backend
- **Cálculo automático** de:
  - IVA (16%)
  - Envío (gratis si > $500, sino $50)

#### 5. Gestión de Órdenes
- **Listado de órdenes** con paginación
- **Estados de orden**:
  - Pendiente
  - Confirmado
  - En proceso
  - Enviado
  - Entregado
  - Cancelado
- **Estados de pago**:
  - Pendiente
  - Pagado
  - Fallido
  - Reembolsado
- **Detalle completo** de cada orden:
  - Productos comprados
  - Dirección de envío
  - Resumen de costos

## Tecnologías

### Dependencias Principales
```yaml
dependencies:
  flutter: sdk
  provider: ^6.1.1              # State management
  http: ^1.2.0                  # HTTP client
  shared_preferences: ^2.2.2    # Local storage
  cached_network_image: ^3.3.1  # Image caching
  url_launcher: ^6.2.3          # Open YouTube videos
  intl: ^0.19.0                 # Formatting (currency, dates)
  flutter_spinkit: ^5.2.0       # Loading indicators
```

## Arquitectura

### Estructura del Proyecto
```
lib/
├── config/
│   ├── api_config.dart       # Configuración del API
│   └── app_theme.dart        # Tema y colores
├── models/
│   ├── user.dart             # Modelo de usuario
│   ├── product.dart          # Modelo de producto
│   ├── cart.dart             # Modelos de carrito
│   ├── order.dart            # Modelos de orden
│   └── category.dart         # Modelo de categoría
├── services/
│   ├── api_service.dart      # Cliente HTTP base
│   ├── auth_service.dart     # Servicio de autenticación
│   ├── product_service.dart  # Servicio de productos
│   ├── cart_service.dart     # Servicio de carrito
│   └── order_service.dart    # Servicio de órdenes
├── providers/
│   ├── auth_provider.dart    # Provider de autenticación
│   ├── cart_provider.dart    # Provider de carrito
│   └── product_provider.dart # Provider de productos
├── screens/
│   ├── home_screen.dart            # Pantalla principal
│   ├── product_detail_screen.dart  # Detalle de producto
│   ├── cart_screen.dart            # Carrito de compras
│   ├── checkout_screen.dart        # Proceso de pago
│   ├── orders_screen.dart          # Lista de órdenes
│   └── order_detail_screen.dart    # Detalle de orden
├── widgets/
│   ├── common_widgets.dart   # Widgets reutilizables
│   └── product_card.dart     # Card de producto
└── main.dart                 # Entry point
```

### Patrones de Diseño

#### Provider Pattern
- **AuthProvider**: Gestiona estado de autenticación
- **CartProvider**: Gestiona estado del carrito
- **ProductProvider**: Gestiona productos y búsqueda

#### Service Layer
- Separación de lógica de negocio
- Comunicación con el backend
- Manejo centralizado de errores

#### Repository Pattern
- Abstracción de fuentes de datos
- Fácil testing y mantenimiento

## Configuración

### Backend
La aplicación se conecta al backend en:
```
http://localhost:3000/api
```

Para cambiar la URL, edita `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### Usuario Público
La app se autentica automáticamente con:
- **Email**: user@ejemplo.com
- **Password**: User123!
- **Rol**: user

## Instalación

### Prerrequisitos
- Flutter SDK 3.10.4 o superior
- Android Studio / VS Code
- Backend corriendo en http://localhost:3000

### Pasos

1. **Clonar el repositorio**
```bash
cd shopping_exercise_app
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Verificar backend**
Asegúrate de que el backend esté corriendo:
```bash
cd ../shopping_exercise_backend
docker-compose up
```

4. **Ejecutar la app**
```bash
flutter run
```

## Características de Desarrollo

### Hot Reload
Flutter soporta hot reload para desarrollo rápido:
- Presiona `r` en la terminal para hot reload
- Presiona `R` para hot restart

### Debug Mode
La app incluye:
- Manejo de errores con mensajes amigables
- Loading states en todas las operaciones
- Validación de formularios
- Estados vacíos informativos

### Performance
- **Infinite scroll** optimizado
- **Caché de imágenes** con cached_network_image
- **Lazy loading** de productos
- **State management** eficiente con Provider

## Testing

Para ejecutar los tests:
```bash
flutter test
```

## Build

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Integración con Backend

### Endpoints Utilizados
- `POST /auth/login` - Login de usuario
- `GET /products` - Listar productos (con paginación, búsqueda, filtros)
- `GET /products/:id` - Detalle de producto
- `GET /categories` - Listar categorías
- `GET /cart` - Obtener carrito
- `POST /cart` - Agregar al carrito
- `PUT /cart/:id` - Actualizar cantidad
- `DELETE /cart/:id` - Eliminar del carrito
- `DELETE /cart` - Vaciar carrito
- `GET /orders` - Listar órdenes
- `GET /orders/:id` - Detalle de orden
- `POST /orders` - Crear orden (checkout)
- `POST /orders/:id/pay` - Simular pago

### Autenticación
Todas las peticiones protegidas incluyen el header:
```
Authorization: Bearer {token}
```

## Simulación de Pago

El pago es **simulado** con el backend:
- **90% de tasa de éxito** (configurable en backend)
- No se procesan pagos reales
- Solo para propósitos de demostración

## Próximas Mejoras

- [ ] Integración con pasarela de pago real
- [ ] Soporte para modo offline
- [ ] Notificaciones push
- [ ] Favoritos/Wishlist
- [ ] Historial de búsquedas
- [ ] Compartir productos
- [ ] Reviews y ratings
- [ ] Dark mode

## Licencia

Este proyecto es un ejercicio educativo.

## Autor

Desarrollado como ejercicio de Flutter + Backend REST API.
