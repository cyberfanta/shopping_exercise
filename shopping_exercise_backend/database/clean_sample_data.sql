-- Script para limpiar productos y categorías de ejemplo
-- Ejecutar este script si ya tienes la base de datos corriendo

-- Eliminar todos los productos de ejemplo
DELETE FROM products WHERE TRUE;

-- Eliminar todas las categorías de ejemplo
DELETE FROM categories WHERE TRUE;

-- Reiniciar las secuencias (opcional, para mantener IDs limpios)
-- Las secuencias UUID no necesitan reinicio, pero si tenías IDs secuenciales:
-- ALTER SEQUENCE products_id_seq RESTART WITH 1;
-- ALTER SEQUENCE categories_id_seq RESTART WITH 1;

-- Verificar que se eliminaron
SELECT COUNT(*) as productos_restantes FROM products;
SELECT COUNT(*) as categorias_restantes FROM categories;

-- Mensaje de confirmación
SELECT 'Base de datos limpiada. Ahora puedes agregar videos de YouTube desde el portal.' as mensaje;

