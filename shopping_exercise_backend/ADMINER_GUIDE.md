# Cómo Acceder a Adminer

## 🌐 Acceso Web

Abre tu navegador y ve a: **http://localhost:8080**

## 🔑 Credenciales de Conexión

Cuando se abra Adminer, usa estos datos:

- **Sistema**: `PostgreSQL`
- **Servidor**: `postgres` ⚠️ **NO uses "localhost"**
- **Usuario**: `postgres`
- **Contraseña**: `postgres123`
- **Base de datos**: `shopping_db`

## ❓ ¿Por qué "postgres" y no "localhost"?

Dentro de Docker, los servicios se comunican entre sí usando sus nombres de servicio definidos en `docker-compose.yml`. El contenedor de Adminer necesita conectarse al contenedor de PostgreSQL usando el nombre `postgres`, no `localhost`.

## 📊 Una vez conectado

Podrás:
- Ver todas las tablas
- Ejecutar queries SQL
- Ver los datos de usuarios, productos, etc.
- Verificar que el superadmin existe

## 🔍 Queries Útiles

### Ver todos los usuarios:
```sql
SELECT email, role, first_name, last_name, is_active FROM users;
```

### Ver todos los productos:
```sql
SELECT name, price, stock, youtube_video_id FROM products;
```

### Ver categorías:
```sql
SELECT name, description FROM categories;
```

