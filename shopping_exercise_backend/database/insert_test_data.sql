-- Script para agregar datos de prueba: carrito y orden
-- Este script crea un usuario de prueba y le agrega un carrito con items y una orden

-- 1. Crear usuario de prueba (si no existe)
-- Password: Test123!
INSERT INTO users (email, password_hash, first_name, last_name, role, is_active) VALUES
('test@ejemplo.com', '$2a$10$NkPYpYMuJWcGVKu4JY1og.XvqYQer2D1fqJbWPYhvrBL2Bdhb3QnC', 'Usuario', 'Prueba', 'user', true)
ON CONFLICT (email) DO UPDATE SET
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name;

-- Obtener el ID del usuario de prueba
DO $$
DECLARE
    test_user_id UUID;
    superadmin_id UUID;
    test_category_id UUID;
    test_product_1_id UUID;
    test_product_2_id UUID;
    test_product_3_id UUID;
    test_cart_1_id UUID;
    test_cart_2_id UUID;
    test_order_1_id UUID;
    test_order_2_id UUID;
    generated_order_number_1 VARCHAR(50);
    generated_order_number_2 VARCHAR(50);
BEGIN
    -- Obtener IDs de usuarios
    SELECT id INTO test_user_id FROM users WHERE email = 'test@ejemplo.com';
    SELECT id INTO superadmin_id FROM users WHERE email = 'julioleon2004@gmail.com';

    -- 2. Crear categoría de prueba
    INSERT INTO categories (name, description, is_active) VALUES
    ('Canal de Prueba', 'Videos de prueba para testing', true)
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_category_id;
    
    IF test_category_id IS NULL THEN
        SELECT id INTO test_category_id FROM categories WHERE name = 'Canal de Prueba';
    END IF;

    -- 3. Crear productos de prueba
    INSERT INTO products (category_id, name, description, price, stock, youtube_video_id, youtube_thumbnail, youtube_channel_id, image_url, is_active) VALUES
    (test_category_id, 'Tutorial de Flutter Completo', 'Aprende Flutter desde cero hasta avanzado', 29.99, 100, 'dQw4w9WgXcQ', 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg', 'UC_canal_prueba', 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg', true)
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_product_1_id;
    
    IF test_product_1_id IS NULL THEN
        SELECT id INTO test_product_1_id FROM products WHERE name = 'Tutorial de Flutter Completo';
    END IF;

    INSERT INTO products (category_id, name, description, price, stock, youtube_video_id, youtube_thumbnail, youtube_channel_id, image_url, is_active) VALUES
    (test_category_id, 'React.js para Principiantes', 'Domina React.js en 5 horas', 24.99, 50, 'abc123xyz', 'https://i.ytimg.com/vi/abc123xyz/hqdefault.jpg', 'UC_canal_prueba', 'https://i.ytimg.com/vi/abc123xyz/hqdefault.jpg', true)
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_product_2_id;
    
    IF test_product_2_id IS NULL THEN
        SELECT id INTO test_product_2_id FROM products WHERE name = 'React.js para Principiantes';
    END IF;

    INSERT INTO products (category_id, name, description, price, stock, youtube_video_id, youtube_thumbnail, youtube_channel_id, image_url, is_active) VALUES
    (test_category_id, 'Node.js Backend Development', 'Crea APIs profesionales con Node.js', 34.99, 75, 'def456uvw', 'https://i.ytimg.com/vi/def456uvw/hqdefault.jpg', 'UC_canal_prueba', 'https://i.ytimg.com/vi/def456uvw/hqdefault.jpg', true)
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_product_3_id;
    
    IF test_product_3_id IS NULL THEN
        SELECT id INTO test_product_3_id FROM products WHERE name = 'Node.js Backend Development';
    END IF;

    -- 4. Crear carrito para el usuario de prueba
    INSERT INTO carts (user_id) VALUES (test_user_id)
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_cart_1_id;
    
    IF test_cart_1_id IS NULL THEN
        SELECT id INTO test_cart_1_id FROM carts WHERE user_id = test_user_id LIMIT 1;
    END IF;

    -- 5. Agregar items al carrito del usuario de prueba
    INSERT INTO cart_items (cart_id, product_id, quantity, price) VALUES
    (test_cart_1_id, test_product_1_id, 2, 29.99),
    (test_cart_1_id, test_product_2_id, 1, 24.99)
    ON CONFLICT (cart_id, product_id) DO UPDATE SET
        quantity = EXCLUDED.quantity,
        price = EXCLUDED.price;

    -- 6. Crear carrito para el superadmin
    INSERT INTO carts (user_id) VALUES (superadmin_id)
    ON CONFLICT DO NOTHING
    RETURNING id INTO test_cart_2_id;
    
    IF test_cart_2_id IS NULL THEN
        SELECT id INTO test_cart_2_id FROM carts WHERE user_id = superadmin_id LIMIT 1;
    END IF;

    -- 7. Agregar items al carrito del superadmin
    INSERT INTO cart_items (cart_id, product_id, quantity, price) VALUES
    (test_cart_2_id, test_product_3_id, 3, 34.99)
    ON CONFLICT (cart_id, product_id) DO UPDATE SET
        quantity = EXCLUDED.quantity,
        price = EXCLUDED.price;

    -- 8. Generar números de orden únicos
    generated_order_number_1 := 'ORD-' || LPAD(FLOOR(RANDOM() * 9999999999)::TEXT, 10, '0') || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));
    generated_order_number_2 := 'ORD-' || LPAD(FLOOR(RANDOM() * 9999999999)::TEXT, 10, '0') || '-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 6));

    -- 9. Crear orden para el usuario de prueba
    INSERT INTO orders (user_id, order_number, subtotal, tax, shipping, total, status, payment_method, shipping_address) VALUES
    (
        test_user_id,
        generated_order_number_1,
        84.97, -- 2x29.99 + 1x24.99
        8.50,  -- 10% tax
        5.00,  -- shipping
        98.47, -- total
        'confirmed',
        'credit_card',
        jsonb_build_object(
            'street', 'Calle Principal 123',
            'city', 'San José',
            'state', 'San José',
            'zipCode', '10101',
            'country', 'Costa Rica'
        )
    )
    RETURNING id INTO test_order_1_id;

    -- 10. Agregar items a la orden del usuario de prueba
    INSERT INTO order_items (order_id, product_id, product_name, product_description, quantity, unit_price, subtotal) VALUES
    (test_order_1_id, test_product_1_id, 'Tutorial de Flutter Completo', 'Aprende Flutter desde cero hasta avanzado', 2, 29.99, 59.98),
    (test_order_1_id, test_product_2_id, 'React.js para Principiantes', 'Domina React.js en 5 horas', 1, 24.99, 24.99);

    -- 11. Crear orden para el superadmin
    INSERT INTO orders (user_id, order_number, subtotal, tax, shipping, total, status, payment_method, shipping_address) VALUES
    (
        superadmin_id,
        generated_order_number_2,
        104.97, -- 1x34.99 + 2x34.99
        10.50,  -- 10% tax
        5.00,   -- shipping
        120.47, -- total
        'pending',
        'paypal',
        jsonb_build_object(
            'street', 'Avenida Central 456',
            'city', 'Heredia',
            'state', 'Heredia',
            'zipCode', '40101',
            'country', 'Costa Rica'
        )
    )
    RETURNING id INTO test_order_2_id;

    -- 12. Agregar items a la orden del superadmin
    INSERT INTO order_items (order_id, product_id, product_name, product_description, quantity, unit_price, subtotal) VALUES
    (test_order_2_id, test_product_3_id, 'Node.js Backend Development', 'Crea APIs profesionales con Node.js', 3, 34.99, 104.97);

    -- Mostrar resumen
    RAISE NOTICE '✅ Datos de prueba insertados correctamente:';
    RAISE NOTICE '   - Usuario de prueba: test@ejemplo.com (password: Test123!)';
    RAISE NOTICE '   - % productos creados', (SELECT COUNT(*) FROM products WHERE category_id = test_category_id);
    RAISE NOTICE '   - 2 carritos creados (1 para usuario prueba, 1 para superadmin)';
    RAISE NOTICE '   - % items en carritos', (SELECT COUNT(*) FROM cart_items WHERE cart_id IN (test_cart_1_id, test_cart_2_id));
    RAISE NOTICE '   - 2 órdenes creadas';
    RAISE NOTICE '   - % items en órdenes', (SELECT COUNT(*) FROM order_items WHERE order_id IN (test_order_1_id, test_order_2_id));
END $$;

-- Mostrar resumen final
SELECT 
    '📊 RESUMEN DE DATOS DE PRUEBA' as titulo;

SELECT 
    'Usuarios' as tabla,
    COUNT(*) as registros
FROM users 
WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')

UNION ALL

SELECT 
    'Productos' as tabla,
    COUNT(*) as registros
FROM products 
WHERE category_id IN (SELECT id FROM categories WHERE name = 'Canal de Prueba')

UNION ALL

SELECT 
    'Carritos' as tabla,
    COUNT(*) as registros
FROM carts 
WHERE user_id IN (SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com'))

UNION ALL

SELECT 
    'Items en carritos' as tabla,
    COUNT(*) as registros
FROM cart_items 
WHERE cart_id IN (SELECT id FROM carts WHERE user_id IN (SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')))

UNION ALL

SELECT 
    'Órdenes' as tabla,
    COUNT(*) as registros
FROM orders 
WHERE user_id IN (SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com'))

UNION ALL

SELECT 
    'Items en órdenes' as tabla,
    COUNT(*) as registros
FROM order_items 
WHERE order_id IN (SELECT id FROM orders WHERE user_id IN (SELECT id FROM users WHERE email IN ('test@ejemplo.com', 'julioleon2004@gmail.com')));
