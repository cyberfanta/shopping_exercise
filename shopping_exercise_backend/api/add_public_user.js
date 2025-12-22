const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

async function addPublicUser() {
  // Usar DATABASE_URL si está disponible (formato: postgresql://user:pass@host:port/db)
  // Si no, usar variables individuales o valores por defecto
  let pool;
  
  if (process.env.DATABASE_URL) {
    pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: false  // No usar SSL en Docker
    });
  } else {
    // Intentar con el nombre del contenedor Docker primero
    pool = new Pool({
      host: process.env.DB_HOST || 'shopping_postgres',
      port: process.env.DB_PORT || 5432,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres123',
      database: process.env.DB_NAME || 'shopping_db',
      ssl: false
    });
  }

  try {
    const email = 'user@ejemplo.com';
    const password = 'User123!';
    const hash = await bcrypt.hash(password, 10);
    
    console.log('🔐 Generando usuario público...');
    console.log('   Email:', email);
    console.log('   Password:', password);
    console.log('   Hash:', hash);
    
    // Insertar o actualizar usuario
    const userResult = await pool.query(
      `INSERT INTO users (email, password_hash, first_name, last_name, phone, role, is_active) 
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (email) DO UPDATE SET
         password_hash = EXCLUDED.password_hash,
         first_name = EXCLUDED.first_name,
         last_name = EXCLUDED.last_name,
         phone = EXCLUDED.phone,
         role = EXCLUDED.role,
         is_active = EXCLUDED.is_active
       RETURNING id, email, first_name, last_name, role`,
      [email, hash, 'Usuario', 'Público', '+123456789', 'user', true]
    );
    
    console.log('✅ Usuario creado/actualizado:', userResult.rows[0]);
    
    // Crear carrito si no existe
    const userId = userResult.rows[0].id;
    await pool.query(
      `INSERT INTO carts (user_id) 
       VALUES ($1)
       ON CONFLICT DO NOTHING`,
      [userId]
    );
    
    console.log('✅ Carrito creado para el usuario');
    
    // Verificar contraseña
    const check = await pool.query(
      'SELECT email, password_hash FROM users WHERE email = $1',
      [email]
    );
    
    const isValid = await bcrypt.compare(password, check.rows[0].password_hash);
    console.log('🔒 Verificación de contraseña:', isValid ? '✅ CORRECTA' : '❌ INCORRECTA');
    
    await pool.end();
    
    console.log('\n📋 Credenciales del usuario público:');
    console.log('   Email: user@ejemplo.com');
    console.log('   Password: User123!');
    console.log('   Role: user');
    
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

addPublicUser();

