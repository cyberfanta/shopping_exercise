# ✅ Corrección de Credenciales del Usuario Test

## 📋 Resumen

Se corrigió el hash de la contraseña del usuario de prueba en la base de datos para que coincida con las credenciales mostradas en el portal de login.

## 🔧 Cambios Realizados

### 1. **Base de Datos**
Se actualizó el `password_hash` del usuario `test@ejemplo.com` para que corresponda a la contraseña `Test123!`.

**Hash correcto:**
```
$2a$10$zOb3.1mSC6Tl8AiMegOY9.KrS0tnSaQUiN8DNz4SsaiW0kvVsIPzq
```

**Comando ejecutado:**
```sql
UPDATE users 
SET password_hash = '$2a$10$zOb3.1mSC6Tl8AiMegOY9.KrS0tnSaQUiN8DNz4SsaiW0kvVsIPzq',
    role = 'user'
WHERE email = 'test@ejemplo.com';
```

### 2. **Script de Datos de Prueba**
Se actualizó `shopping_exercise_backend/database/insert_test_data.sql` para incluir el hash correcto y asegurar que se actualice en conflictos:

```sql
-- Password: Test123!
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active) VALUES
('test@ejemplo.com', '$2a$10$zOb3.1mSC6Tl8AiMegOY9.KrS0tnSaQUiN8DNz4SsaiW0kvVsIPzq', 'Usuario', 'Prueba', 'user', true)
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name;
```

### 3. **Portal de Login**
El componente de "Credenciales de prueba" ya mostraba las credenciales correctas:

```
Email: test@ejemplo.com
Password: Test123!
```

Los campos de entrada **NO** están prellenados, el usuario debe copiar las credenciales manualmente.

## ✅ Verificación

Se probó el login con las credenciales corregidas:

```powershell
$body = @{email='test@ejemplo.com';password='Test123!'} | ConvertTo-Json
Invoke-RestMethod -Uri 'http://localhost:3000/api/auth/login' -Method POST -Body $body -ContentType 'application/json'
```

**Resultado exitoso:**
```json
{
    "message": "Login successful",
    "user": {
        "id": "00000000-0000-0000-0000-000000000001",
        "email": "test@ejemplo.com",
        "first_name": "Usuario",
        "last_name": "Prueba",
        "phone": null,
        "role": "user",
        "is_active": true
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

## 📝 Credenciales Disponibles

### Usuario de Prueba (Rol: user)
- **Email:** `test@ejemplo.com`
- **Password:** `Test123!`
- **Rol:** `user`

### Usuario Superadmin (Rol: superadmin)
- **Email:** `julioleon2004@gmail.com`
- **Password:** `Admin123!`
- **Rol:** `superadmin`
- **Nota:** Este usuario NO puede ser eliminado del sistema.

## 🎯 Estado Final

✅ Hash de contraseña corregido en la base de datos
✅ Script de datos de prueba actualizado con el hash correcto
✅ Portal mostrando las credenciales correctas
✅ Login funcionando correctamente con ambos usuarios
✅ Campos de entrada sin prellenado automático

---

**Fecha:** 20 de diciembre de 2025

