const { validationResult } = require('express-validator');
const pool = require('../config/database');

const orderController = {
  // Get user's orders
  async getUserOrders(req, res) {
    try {
      const userId = req.user.id;

      const result = await pool.query(
        `SELECT 
          o.*,
          COUNT(oi.id) as items_count
        FROM orders o
        LEFT JOIN order_items oi ON o.id = oi.order_id
        WHERE o.user_id = $1
        GROUP BY o.id
        ORDER BY o.created_at DESC`,
        [userId]
      );

      res.json({ orders: result.rows });
    } catch (error) {
      console.error('Get user orders error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get single order
  async getOrderById(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const order = await pool.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
        [id, userId]
      );

      if (order.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Order not found', status: 404 } });
      }

      const items = await pool.query(
        'SELECT * FROM order_items WHERE order_id = $1',
        [id]
      );

      res.json({
        order: {
          ...order.rows[0],
          items: items.rows
        }
      });
    } catch (error) {
      console.error('Get order by id error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Create order from cart (checkout)
  async createOrder(req, res) {
    const client = await pool.connect();
    
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { payment_method, shipping_address, notes } = req.body;

      await client.query('BEGIN');

      // Get cart items
      const cart = await client.query('SELECT id FROM carts WHERE user_id = $1', [userId]);
      
      if (cart.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: { message: 'Cart is empty', status: 400 } });
      }

      const cartId = cart.rows[0].id;

      const cartItems = await client.query(
        `SELECT 
          ci.*,
          p.name,
          p.description,
          p.stock
        FROM cart_items ci
        JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = $1 AND p.is_active = true`,
        [cartId]
      );

      if (cartItems.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: { message: 'Cart is empty', status: 400 } });
      }

      // Check stock for all items
      for (const item of cartItems.rows) {
        if (item.stock < item.quantity) {
          await client.query('ROLLBACK');
          return res.status(400).json({
            error: {
              message: `Insufficient stock for ${item.name}`,
              status: 400
            }
          });
        }
      }

      // Calculate totals
      const subtotal = cartItems.rows.reduce((sum, item) => {
        return sum + (parseFloat(item.price) * item.quantity);
      }, 0);
      
      const tax = subtotal * 0.16; // 16% IVA
      const shipping = subtotal > 500 ? 0 : 50; // Free shipping over $500
      const total = subtotal + tax + shipping;

      // Generate order number
      const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substring(7).toUpperCase()}`;

      // Create order
      const order = await client.query(
        `INSERT INTO orders (
          user_id, order_number, status, subtotal, tax, shipping, total,
          payment_method, shipping_address, notes
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
        RETURNING *`,
        [
          userId,
          orderNumber,
          'pending',
          subtotal.toFixed(2),
          tax.toFixed(2),
          shipping.toFixed(2),
          total.toFixed(2),
          payment_method,
          JSON.stringify(shipping_address),
          notes || null
        ]
      );

      const orderId = order.rows[0].id;

      // Create order items and update stock
      for (const item of cartItems.rows) {
        await client.query(
          `INSERT INTO order_items (
            order_id, product_id, product_name, product_description,
            quantity, unit_price, subtotal
          ) VALUES ($1, $2, $3, $4, $5, $6, $7)`,
          [
            orderId,
            item.product_id,
            item.name,
            item.description,
            item.quantity,
            item.price,
            (parseFloat(item.price) * item.quantity).toFixed(2)
          ]
        );

        // Update product stock
        await client.query(
          'UPDATE products SET stock = stock - $1 WHERE id = $2',
          [item.quantity, item.product_id]
        );
      }

      // Clear cart
      await client.query('DELETE FROM cart_items WHERE cart_id = $1', [cartId]);

      await client.query('COMMIT');

      res.status(201).json({
        message: 'Order created successfully',
        order: order.rows[0]
      });
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Create order error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    } finally {
      client.release();
    }
  },

  // Simulate payment
  async simulatePayment(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      // Get order
      const order = await pool.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
        [id, userId]
      );

      if (order.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Order not found', status: 404 } });
      }

      if (order.rows[0].payment_status === 'paid') {
        return res.status(400).json({ error: { message: 'Order already paid', status: 400 } });
      }

      // Simulate payment success (in production, integrate with payment gateway)
      const paymentSuccess = Math.random() > 0.1; // 90% success rate

      if (paymentSuccess) {
        await pool.query(
          `UPDATE orders 
           SET payment_status = 'paid', status = 'confirmed' 
           WHERE id = $1`,
          [id]
        );

        res.json({
          message: 'Payment processed successfully',
          payment_status: 'paid',
          order_status: 'confirmed'
        });
      } else {
        await pool.query(
          `UPDATE orders 
           SET payment_status = 'failed' 
           WHERE id = $1`,
          [id]
        );

        res.status(400).json({
          error: {
            message: 'Payment failed. Please try again.',
            status: 400
          }
        });
      }
    } catch (error) {
      console.error('Simulate payment error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Cancel order
  async cancelOrder(req, res) {
    const client = await pool.connect();
    
    try {
      const userId = req.user.id;
      const { id } = req.params;

      await client.query('BEGIN');

      // Get order
      const order = await client.query(
        'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
        [id, userId]
      );

      if (order.rows.length === 0) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: { message: 'Order not found', status: 404 } });
      }

      if (order.rows[0].status === 'cancelled') {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: { message: 'Order already cancelled', status: 400 } });
      }

      if (['shipped', 'delivered'].includes(order.rows[0].status)) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: { message: 'Cannot cancel shipped/delivered order', status: 400 } });
      }

      // Get order items and restore stock
      const items = await client.query(
        'SELECT product_id, quantity FROM order_items WHERE order_id = $1',
        [id]
      );

      for (const item of items.rows) {
        await client.query(
          'UPDATE products SET stock = stock + $1 WHERE id = $2',
          [item.quantity, item.product_id]
        );
      }

      // Cancel order
      await client.query(
        `UPDATE orders SET status = 'cancelled' WHERE id = $1`,
        [id]
      );

      await client.query('COMMIT');

      res.json({ message: 'Order cancelled successfully' });
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Cancel order error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    } finally {
      client.release();
    }
  }
};

module.exports = orderController;

