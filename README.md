# Shopping Exercise

## 🌐 Sitios Desplegados

Todos los servicios están desplegados en EC2 y disponibles en:

- **🏠 Landing Page**: [http://100.49.43.143/](http://100.49.43.143/)
- **🛍️ App de Compras**: [http://100.49.43.143/app](http://100.49.43.143/app)
- **⚙️ Portal Administrativo**: [http://100.49.43.143/portal](http://100.49.43.143/portal)
- **🔌 API Backend**: [http://100.49.43.143/api](http://100.49.43.143/api)
- **🗄️ Adminer (DB)**: [http://100.49.43.143/adminer](http://100.49.43.143/adminer)
- **💚 Health Check**: [http://100.49.43.143/health](http://100.49.43.143/health)

### 🔐 Credenciales de Prueba

**App de Compras:**

- Email: `user@ejemplo.com`
- Password: `User123!`

**Portal Administrativo:**

- Email: `test@ejemplo.com`
- Password: `Test123!`

---

Monorepo con 2 aplicaciones Flutter y backend.

## 📂 Estructura del Proyecto

```
shopping_exercise/
├── shopping_exercise_app/     # Aplicación Flutter para clientes
├── shopping_exercise_portal/  # Portal Flutter para administración
└── shopping_exercise_backend/ # Backend API con Docker
```

## 🔗 Backend API

El proyecto incluye un backend completo con Node.js y PostgreSQL.

**Ver documentación completa de endpoints**: [shopping_exercise_backend/API_ENDPOINTS.md](./shopping_exercise_backend/API_ENDPOINTS.md)

### Características del Backend:
- ✅ Autenticación completa (login, registro, reset de contraseña)
- ✅ Gestión de productos y categorías
- ✅ Carrito de compras
- ✅ Sistema de órdenes/pedidos
- ✅ Simulación de pagos
- ✅ Base de datos PostgreSQL
- ✅ Docker ready

### Iniciar el Backend:
```bash
cd shopping_exercise_backend
docker-compose up -d
```

El API estará disponible en: http://localhost:3000

## 📱 Aplicaciones Flutter

### Shopping Exercise App
Aplicación móvil para clientes del e-commerce.

### Shopping Exercise Portal
Portal de administración para gestionar productos, órdenes, etc.

## 🚀 Inicio Rápido

1. **Backend**:
```bash
cd shopping_exercise_backend
cp api/.env.example api/.env
# Editar .env con tus credenciales
docker-compose up -d
```

2. **Apps Flutter**:
```bash
cd shopping_exercise_app
flutter pub get
flutter run
```

## 📄 Licencia

MIT

