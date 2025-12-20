const { Pool } = require('pg');
const bcrypt = require('bcryptjs');

async function updatePassword() {
  const pool = new Pool({
    host: 'postgres',
    port: 5432,
    user: 'postgres',
    password: 'postgres123',
    database: 'shopping_db'
  });

  try {
    const password = 'Admin123!';
    const hash = await bcrypt.hash(password, 10);
    
    console.log('Hash generado:', hash);
    
    const result = await pool.query(
      "UPDATE users SET password_hash = $1 WHERE email = 'julioleon2004@gmail.com' RETURNING email, LEFT(password_hash, 15) as hash_preview",
      [hash]
    );
    
    console.log('Usuario actualizado:', result.rows[0]);
    
    // Verificar
    const check = await pool.query(
      "SELECT email, password_hash FROM users WHERE email = 'julioleon2004@gmail.com'"
    );
    
    const isValid = await bcrypt.compare(password, check.rows[0].password_hash);
    console.log('Verificación de contraseña:', isValid);
    
    await pool.end();
  } catch (error) {
    console.error('Error:', error);
  }
}

updatePassword();


