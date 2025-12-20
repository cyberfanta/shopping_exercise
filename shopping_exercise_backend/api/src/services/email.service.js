const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

const emailService = {
  // Send password reset email
  async sendPasswordResetEmail(to, firstName, resetUrl) {
    try {
      const mailOptions = {
        from: process.env.SMTP_FROM,
        to,
        subject: 'Restablecer tu contraseña - Shopping Exercise',
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
              .content { padding: 20px; background-color: #f9f9f9; }
              .button { display: inline-block; padding: 12px 24px; background-color: #4CAF50; 
                        color: white; text-decoration: none; border-radius: 4px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Restablecer Contraseña</h1>
              </div>
              <div class="content">
                <p>Hola ${firstName},</p>
                <p>Recibimos una solicitud para restablecer tu contraseña. Si no realizaste esta solicitud, 
                   puedes ignorar este correo de forma segura.</p>
                <p>Para restablecer tu contraseña, haz clic en el siguiente botón:</p>
                <p style="text-align: center;">
                  <a href="${resetUrl}" class="button">Restablecer Contraseña</a>
                </p>
                <p>O copia y pega este enlace en tu navegador:</p>
                <p style="word-break: break-all;">${resetUrl}</p>
                <p><strong>Este enlace expirará en 1 hora.</strong></p>
                <p>Saludos,<br>El equipo de Shopping Exercise</p>
              </div>
              <div class="footer">
                <p>Este es un correo automático, por favor no respondas.</p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      const info = await transporter.sendMail(mailOptions);
      console.log('Email sent:', info.messageId);
      return info;
    } catch (error) {
      console.error('Error sending email:', error);
      // Don't throw error to prevent revealing email existence
      return null;
    }
  },

  // Send order confirmation email
  async sendOrderConfirmationEmail(to, firstName, order) {
    try {
      const mailOptions = {
        from: process.env.SMTP_FROM,
        to,
        subject: `Confirmación de pedido ${order.order_number} - Shopping Exercise`,
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
              .content { padding: 20px; background-color: #f9f9f9; }
              .footer { text-align: center; padding: 20px; font-size: 12px; color: #666; }
              .order-details { margin: 20px 0; }
              .total { font-size: 18px; font-weight: bold; margin-top: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>¡Pedido Confirmado!</h1>
              </div>
              <div class="content">
                <p>Hola ${firstName},</p>
                <p>Gracias por tu compra. Hemos recibido tu pedido y lo estamos preparando.</p>
                <div class="order-details">
                  <p><strong>Número de pedido:</strong> ${order.order_number}</p>
                  <p><strong>Total:</strong> $${order.total}</p>
                </div>
                <p>Te enviaremos una notificación cuando tu pedido sea enviado.</p>
                <p>Saludos,<br>El equipo de Shopping Exercise</p>
              </div>
              <div class="footer">
                <p>Este es un correo automático, por favor no respondas.</p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      const info = await transporter.sendMail(mailOptions);
      console.log('Order confirmation email sent:', info.messageId);
      return info;
    } catch (error) {
      console.error('Error sending order confirmation email:', error);
      return null;
    }
  }
};

module.exports = emailService;

