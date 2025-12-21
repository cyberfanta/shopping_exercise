# 🎥 Cómo Obtener YouTube API Key

## 📝 Pasos Detallados:

### 1. Ir a Google Cloud Console
Ve a: https://console.cloud.google.com/

### 2. Crear un Proyecto (si no tienes uno)
1. Haz clic en el selector de proyectos (arriba a la izquierda)
2. Clic en "NEW PROJECT"
3. Nombre: `Shopping Exercise YouTube` (o el que prefieras)
4. Clic en "CREATE"

### 3. Habilitar YouTube Data API v3
1. En el menú lateral, ve a **"APIs & Services" > "Library"**
2. Busca: `YouTube Data API v3`
3. Haz clic en el resultado
4. Clic en **"ENABLE"**

### 4. Crear Credenciales (API Key)
1. Ve a **"APIs & Services" > "Credentials"**
2. Clic en **"+ CREATE CREDENTIALS"**
3. Selecciona **"API key"**
4. Se creará la API key y aparecerá en un popup
5. **¡COPIA LA API KEY!** Se ve algo así: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

### 5. (Opcional) Restringir la API Key
Para mayor seguridad:
1. En el popup de la API key, clic en "RESTRICT KEY"
2. En "API restrictions":
   - Selecciona "Restrict key"
   - Marca solo: **YouTube Data API v3**
3. Guarda los cambios

### 6. Configurar en el Backend
Edita el archivo `.env` en `shopping_exercise_backend/api/.env`:

```env
YOUTUBE_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### 7. Reiniciar Docker
```bash
cd shopping_exercise_backend
docker-compose restart api
```

## 📊 Cuota de YouTube API

**Cuota diaria gratuita:** 10,000 unidades/día

**Costos de operaciones:**
- Search (búsqueda): 100 unidades
- Videos.list (detalles): 1 unidad

**Ejemplo:**
- 100 búsquedas al día = 10,000 unidades ✅
- Más que suficiente para desarrollo y pruebas

## ✅ Verificar que Funciona

Una vez configurada la API key, prueba:

```bash
# Desde PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/api/youtube/search?q=flutter&maxResults=5" -Headers @{"Authorization"="Bearer TU_TOKEN_JWT"}
```

Deberías ver resultados reales de YouTube en lugar de datos de ejemplo.

## 🔗 Enlaces Útiles

- **Google Cloud Console**: https://console.cloud.google.com/
- **YouTube Data API Docs**: https://developers.google.com/youtube/v3
- **Cuotas y límites**: https://developers.google.com/youtube/v3/getting-started#quota

## ⚠️ Importante

- **NO compartas tu API key** en repositorios públicos
- Ya está en `.gitignore`, pero verifica antes de hacer commits
- Si expones tu key accidentalmente, regenerala inmediatamente en Google Cloud Console

---

## 🎉 ¡Listo!

Una vez tengas tu API key configurada, el portal podrá buscar videos reales de YouTube.

