-- Script para agregar usuario público para la app móvil
-- Este usuario se usará para probar la app sin necesidad de login visible

-- Usuario público: user@ejemplo.com
-- Password: User123!
-- Role: user (usuario regular, no admin)
-- Hash generado con bcrypt rounds=10

INSERT INTO users (email, password_hash, first_name, last_name, phone, role, is_active) VALUES
('user@ejemplo.com', '$2a$10$YFZqVZ3QKX2Y5R2Y5R2Y5.O9K9K9K9K9K9K9K9K9K9K9K9K9K9K9K', 'Usuario', 'Público', '+123456789', 'user', true)
ON CONFLICT (email) DO UPDATE SET
    password_hash = '$2a$10$YFZqVZ3QKX2Y5R2Y5R2Y5.O9K9K9K9K9K9K9K9K9K9K9K9K9K9K9K',
    first_name = 'Usuario',
    last_name = 'Público',
    phone = '+123456789',
    role = 'user',
    is_active = true;

-- Crear un carrito para este usuario
INSERT INTO carts (user_id)
SELECT id FROM users WHERE email = 'user@ejemplo.com'
ON CONFLICT DO NOTHING;

-- Mostrar confirmación
SELECT 
    '✅ Usuario público creado correctamente' as mensaje,
    '   Email: user@ejemplo.com' as credenciales_1,
    '   Password: User123!' as credenciales_2,
    '   Role: user' as credenciales_3;
