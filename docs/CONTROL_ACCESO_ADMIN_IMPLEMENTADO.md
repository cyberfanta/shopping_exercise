# ✅ Control de Acceso Administrativo Implementado

## 📋 Resumen

Se implementó un control de acceso estricto para el portal administrativo, asegurando que solo usuarios con roles de `admin` o `superadmin` puedan acceder al sistema.

## 🔒 Cambios Implementados

### 1. **Backend - Middleware de Administrador**
El middleware `admin.middleware.js` ya estaba configurado correctamente para aceptar tanto usuarios con rol `admin` como `superadmin`:

```javascript
// Check if user is admin or superadmin
if (req.user.role !== 'admin' && req.user.role !== 'superadmin') {
  return res.status(403).json({ 
    error: { 
      message: 'Access denied. Admin privileges required.', 
      status: 403 
    } 
  });
}
```

### 2. **Frontend - Validación de Roles en Login**
Se agregó validación en el `AuthCubit` para rechazar usuarios que no sean administradores:

**Archivo:** `shopping_exercise_portal/lib/features/auth/presentation/cubit/auth_cubit.dart`

```dart
Future<void> login(String email, String password) async {
  try {
    emit(AuthLoading());
    final result = await _authService.login(email, password);
    final user = result['user'] as User;
    
    // Verificar que el usuario sea admin o superadmin
    if (user.role != 'admin' && user.role != 'superadmin') {
      emit(AuthError('Acceso denegado. Se requieren privilegios de administrador.'));
      emit(AuthUnauthenticated());
      return;
    }
    
    emit(AuthAuthenticated(user: user, token: result['token']));
  } catch (e) {
    emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    emit(AuthUnauthenticated());
  }
}
```

### 3. **Frontend - Validación de Roles al Verificar Sesión**
También se agregó validación en el método `checkAuth()` para cerrar sesión automáticamente si el usuario logueado no es administrador:

```dart
Future<void> checkAuth() async {
  emit(AuthLoading());
  final auth = await _authService.checkAuth();
  
  if (auth != null) {
    final user = auth['user'] as User;
    
    // Verificar que el usuario sea admin o superadmin
    if (user.role != 'admin' && user.role != 'superadmin') {
      await _authService.logout();
      emit(AuthUnauthenticated());
      return;
    }
    
    emit(AuthAuthenticated(user: user, token: auth['token']));
  } else {
    emit(AuthUnauthenticated());
  }
}
```

### 4. **Base de Datos - Usuario Test Actualizado**
Se actualizó el usuario de prueba para tener rol `admin`:

```sql
UPDATE users SET role = 'admin' WHERE email = 'test@ejemplo.com';
```

### 5. **Script de Datos de Prueba Actualizado**
Se actualizó `insert_test_data.sql` para crear el usuario test como `admin`:

```sql
-- Password: Test123!
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active) VALUES
('test@ejemplo.com', '$2a$10$zOb3.1mSC6Tl8AiMegOY9.KrS0tnSaQUiN8DNz4SsaiW0kvVsIPzq', 'Usuario', 'Prueba', 'admin', true)
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    role = EXCLUDED.role;
```

### 6. **Portal de Login Actualizado**
Se actualizó el componente de credenciales para indicar que es un usuario administrador:

```dart
Text(
  'Credenciales de prueba (Admin):',
  style: Theme.of(context).textTheme.labelLarge,
),
```

## 🎯 Comportamiento del Sistema

### ✅ Acceso Permitido
Los siguientes roles **PUEDEN** acceder al portal administrativo:
- `admin` - Usuarios administradores
- `superadmin` - Usuarios super administradores (como `julioleon2004@gmail.com`)

### ❌ Acceso Denegado
Los siguientes roles **NO PUEDEN** acceder al portal:
- `user` - Usuarios normales
- Cualquier otro rol no administrativo

### Flujo de Validación

1. **Login:** Cuando un usuario intenta loguearse:
   - Si el rol es `admin` o `superadmin`: ✅ Acceso concedido
   - Si el rol es `user` u otro: ❌ Error "Acceso denegado. Se requieren privilegios de administrador."

2. **Verificación de Sesión:** Al recargar la página o verificar sesión existente:
   - Si el rol es `admin` o `superadmin`: ✅ Mantiene la sesión
   - Si el rol es `user` u otro: ❌ Cierra sesión automáticamente

3. **Endpoints del Backend:** Todos los endpoints administrativos (`/api/admin/*`, `/api/users`, `/api/products`, etc.):
   - Si el rol es `admin` o `superadmin`: ✅ Acceso permitido
   - Si el rol es `user` u otro: ❌ HTTP 403 "Access denied. Admin privileges required."

## 📝 Credenciales Actualizadas

### Usuario Administrador (Prueba)
- **Email:** `test@ejemplo.com`
- **Password:** `Test123!`
- **Rol:** `admin`
- **Acceso:** ✅ Portal administrativo y todos los endpoints

### Usuario Super Administrador
- **Email:** `julioleon2004@gmail.com`
- **Password:** `Admin123!`
- **Rol:** `superadmin`
- **Acceso:** ✅ Portal administrativo y todos los endpoints
- **Protección:** ❌ NO puede ser eliminado del sistema

## ✅ Verificación de Funcionamiento

Se verificó que el usuario `admin` puede acceder a todos los endpoints:

```powershell
# Login exitoso con rol admin
$response = Invoke-RestMethod -Uri 'http://localhost:3000/api/auth/login' -Method POST -Body $body -ContentType 'application/json'
# Resultado: role: "admin"

# Acceso a endpoint administrativo exitoso
$headers = @{Authorization="Bearer $token"}
Invoke-RestMethod -Uri 'http://localhost:3000/api/admin/carts' -Method GET -Headers $headers
# Resultado: ✅ Datos de carritos retornados correctamente
```

## 🔐 Seguridad

### Capas de Protección

1. **Frontend (Flutter):**
   - Validación en `AuthCubit` al hacer login
   - Validación en `AuthCubit` al verificar sesión existente
   - Cierre automático de sesión si el rol no es válido

2. **Backend (Node.js):**
   - Middleware `adminMiddleware` en todas las rutas administrativas
   - Validación de rol en JWT
   - Respuesta HTTP 403 para accesos no autorizados

3. **Base de Datos:**
   - Columna `role` en tabla `users`
   - Valores permitidos: `user`, `admin`, `superadmin`
   - Protección contra eliminación del usuario `julioleon2004@gmail.com`

### Principios de Seguridad Aplicados

- ✅ **Defensa en profundidad:** Validación en múltiples capas (frontend + backend)
- ✅ **Principio de menor privilegio:** Solo usuarios con roles específicos tienen acceso
- ✅ **Fail-secure:** En caso de duda, se cierra la sesión y se niega el acceso
- ✅ **Validación del lado del servidor:** El backend siempre valida independientemente del frontend

---

**Fecha:** 20 de diciembre de 2025
**Estado:** ✅ Implementado y verificado

