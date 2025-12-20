# Shopping Exercise Portal

Portal de administración responsivo para gestionar productos y usuarios del e-commerce.

## ✨ Características

- 🎨 **Diseño moderno** con Material Design 3
- 🎨 **Colores pasteles suaves** (lavanda, melocotón, verde menta)
- 📱 **Totalmente responsivo** (móvil, tablet, desktop)
- 🔐 **Sistema de login** con autenticación JWT
- 📦 **Gestión de productos** con videos de YouTube
- 👥 **Gestión de usuarios** con roles (user, admin, superadmin)
- 🎥 **Integración con YouTube API** para productos como videos
- 🛡️ **Cuenta superadmin** protegida (julioleon2004@gmail.com)

## 🚀 Inicio Rápido

1. **Instalar dependencias**:
```bash
flutter pub get
```

2. **Configurar backend**:
Asegúrate de que el backend esté corriendo en `http://localhost:3000`

3. **Ejecutar la aplicación**:
```bash
flutter run -d chrome  # Para web
flutter run            # Para dispositivo móvil
```

## 🔑 Credenciales de Prueba

- **Email**: julioleon2004@gmail.com
- **Password**: Admin123!
- **Rol**: SuperAdmin

## 📋 Funcionalidades

### Gestión de Productos
- ✅ Ver lista de productos en grid responsivo
- ✅ Crear productos manualmente o desde YouTube
- ✅ Editar productos existentes
- ✅ Eliminar productos
- ✅ Buscar y filtrar por categoría
- ✅ Integración con YouTube API

### Gestión de Usuarios
- ✅ Ver lista de usuarios en tabla
- ✅ Editar información de usuarios
- ✅ Cambiar roles (solo superadmin)
- ✅ Activar/desactivar usuarios
- ✅ Eliminar usuarios (excepto superadmin)
- ✅ Búsqueda y filtros por rol

## 🎨 Paleta de Colores

- **Primary**: #B39DDB (Lavanda suave)
- **Secondary**: #FFCCBC (Melocotón suave)
- **Accent**: #A5D6A7 (Verde menta suave)
- **Background**: #FAFAFA (Blanco ligeramente gris)
- **Surface**: #FFFFFF (Blanco)

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── config/          # Configuración (API URLs)
│   ├── models/          # Modelos de datos
│   └── theme/           # Tema de la aplicación
├── features/
│   ├── auth/            # Autenticación
│   ├── dashboard/       # Dashboard principal
│   ├── products/        # Gestión de productos
│   └── users/           # Gestión de usuarios
└── main.dart
```

## 🔗 Endpoints del Backend

- **Auth**: `/api/auth/*`
- **Products**: `/api/products/*`
- **Categories**: `/api/categories/*`
- **Users**: `/api/users/*`
- **YouTube**: `/api/youtube/*`

Ver documentación completa en: `../shopping_exercise_backend/API_ENDPOINTS.md`

## 📝 Notas

- El superadmin (julioleon2004@gmail.com) no puede ser eliminado ni desactivado
- Solo el superadmin puede asignar roles de admin/superadmin
- Los productos pueden ser videos de YouTube o productos tradicionales
- La búsqueda de YouTube requiere API key configurada en el backend
