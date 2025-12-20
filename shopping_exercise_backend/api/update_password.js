const bcrypt = require('bcryptjs');

async function updatePassword() {
  const password = 'Admin123!';
  const hash = await bcrypt.hash(password, 10);
  console.log('Hash generado:', hash);
  
  // Verificar que funciona
  const isValid = await bcrypt.compare(password, hash);
  console.log('Verificación:', isValid);
  console.log('\nQuery SQL:');
  console.log(`UPDATE users SET password_hash = '${hash}' WHERE email = 'julioleon2004@gmail.com';`);
}

updatePassword().catch(console.error);


