const { validationResult } = require('express-validator');
const pool = require('../config/database');

const adminController = {
  // Get all carts with user information
  async getAllCarts(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;

      // Get all carts with items
      const query = `
        SELECT 
          c.id as cart_id,
          c.user_id,
          u.email as user_email,
          u.first_name,
          u.last_name,
          COUNT(ci.id) as items_count,
          COALESCE(SUM(ci.quantity * ci.price), 0) as subtotal,
          c.updated_at,
          json_agg(
            json_build_object(
              'id', ci.id,
              'product_id', ci.product_id,
              'product_name', p.name,
              'price', ci.price,
              'quantity', ci.quantity,
              'subtotal', ci.quantity * ci.price,
              'youtube_thumbnail', p.youtube_thumbnail
            )
          ) FILTER (WHERE ci.id IS NOT NULL) as items
        FROM carts c
        JOIN users u ON c.user_id = u.id
        LEFT JOIN cart_items ci ON c.id = ci.cart_id
        LEFT JOIN products p ON ci.product_id = p.id
        GROUP BY c.id, c.user_id, u.email, u.first_name, u.last_name, c.updated_at
        HAVING COUNT(ci.id) > 0
        ORDER BY c.updated_at DESC
        LIMIT $1 OFFSET $2
      `;

      const countQuery = `
        SELECT COUNT(DISTINCT c.id) 
        FROM carts c
        JOIN cart_items ci ON c.id = ci.cart_id
      `;

      const [cartsResult, countResult] = await Promise.all([
        pool.query(query, [limit, offset]),
        pool.query(countQuery)
      ]);

      const totalItems = parseInt(countResult.rows[0].count);

      res.json({
        carts: cartsResult.rows,
        pagination: {
          page,
          limit,
          totalItems,
          totalPages: Math.ceil(totalItems / limit)
        }
      });
    } catch (error) {
      console.error('Get all carts error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get cart by user ID
  async getCartByUserId(req, res) {
    try {
      const { userId } = req.params;

      const cartQuery = `
        SELECT 
          c.id as cart_id,
          c.user_id,
          u.email as user_email,
          u.first_name,
          u.last_name,
          c.updated_at
        FROM carts c
        JOIN users u ON c.user_id = u.id
        WHERE c.user_id = $1
      `;

      const itemsQuery = `
        SELECT 
          ci.id,
          ci.product_id,
          p.name as product_name,
          ci.price,
          ci.quantity,
          ci.quantity * ci.price as subtotal,
          p.youtube_thumbnail
        FROM cart_items ci
        JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = (SELECT id FROM carts WHERE user_id = $1)
      `;

      const [cartResult, itemsResult] = await Promise.all([
        pool.query(cartQuery, [userId]),
        pool.query(itemsQuery, [userId])
      ]);

      if (cartResult.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Cart not found', status: 404 } });
      }

      const cart = cartResult.rows[0];
      const items = itemsResult.rows;
      const subtotal = items.reduce((sum, item) => sum + parseFloat(item.subtotal), 0);

      res.json({
        cart: {
          ...cart,
          items_count: items.length,
          subtotal: subtotal.toFixed(2),
          items
        }
      });
    } catch (error) {
      console.error('Get cart by user ID error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Clear cart for a specific user
  async clearUserCart(req, res) {
    try {
      const { userId } = req.params;

      // Get cart ID
      const cartResult = await pool.query(
        'SELECT id FROM carts WHERE user_id = $1',
        [userId]
      );

      if (cartResult.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Cart not found', status: 404 } });
      }

      const cartId = cartResult.rows[0].id;

      // Delete all items from cart
      await pool.query('DELETE FROM cart_items WHERE cart_id = $1', [cartId]);

      res.json({ message: 'Cart cleared successfully' });
    } catch (error) {
      console.error('Clear user cart error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get cart statistics
  async getCartStats(req, res) {
    try {
      const statsQuery = `
        SELECT 
          COUNT(DISTINCT c.id) as total_active_carts,
          COUNT(ci.id) as total_items,
          COALESCE(SUM(ci.quantity), 0) as total_quantity,
          COALESCE(SUM(ci.quantity * ci.price), 0) as total_value,
          COALESCE(AVG(items_per_cart.count), 0) as avg_items_per_cart
        FROM carts c
        LEFT JOIN cart_items ci ON c.id = ci.cart_id
        LEFT JOIN (
          SELECT cart_id, COUNT(*) as count
          FROM cart_items
          GROUP BY cart_id
        ) items_per_cart ON c.id = items_per_cart.cart_id
      `;

      const result = await pool.query(statsQuery);
      const stats = result.rows[0];

      res.json({
        stats: {
          total_active_carts: parseInt(stats.total_active_carts),
          total_items: parseInt(stats.total_items),
          total_quantity: parseInt(stats.total_quantity),
          total_value: parseFloat(stats.total_value).toFixed(2),
          avg_items_per_cart: parseFloat(stats.avg_items_per_cart).toFixed(2)
        }
      });
    } catch (error) {
      console.error('Get cart stats error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get all orders with user information
  async getAllOrders(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 20;
      const offset = (page - 1) * limit;
      const status = req.query.status; // Optional filter

      // Build query with optional status filter
      let query = `
        SELECT 
          o.*,
          u.email as user_email,
          u.first_name as user_first_name,
          u.last_name as user_last_name,
          COUNT(oi.id) as items_count
        FROM orders o
        JOIN users u ON o.user_id = u.id
        LEFT JOIN order_items oi ON o.id = oi.order_id
      `;

      const queryParams = [];
      if (status) {
        query += ' WHERE o.status = $1';
        queryParams.push(status);
      }

      query += `
        GROUP BY o.id, u.email, u.first_name, u.last_name
        ORDER BY o.created_at DESC
        LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
      `;
      queryParams.push(limit, offset);

      // Build count query
      let countQuery = 'SELECT COUNT(*) FROM orders o';
      const countParams = [];
      if (status) {
        countQuery += ' WHERE o.status = $1';
        countParams.push(status);
      }

      const [ordersResult, countResult] = await Promise.all([
        pool.query(query, queryParams),
        pool.query(countQuery, countParams)
      ]);

      const totalItems = parseInt(countResult.rows[0].count);

      res.json({
        orders: ordersResult.rows,
        pagination: {
          page,
          limit,
          totalItems,
          totalPages: Math.ceil(totalItems / limit)
        }
      });
    } catch (error) {
      console.error('Get all orders error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get order by ID (admin)
  async getOrderById(req, res) {
    try {
      const { orderId } = req.params;

      const orderQuery = `
        SELECT 
          o.*,
          u.email as user_email,
          u.first_name as user_first_name,
          u.last_name as user_last_name
        FROM orders o
        JOIN users u ON o.user_id = u.id
        WHERE o.id = $1
      `;

      const itemsQuery = `
        SELECT * FROM order_items WHERE order_id = $1
      `;

      const [orderResult, itemsResult] = await Promise.all([
        pool.query(orderQuery, [orderId]),
        pool.query(itemsQuery, [orderId])
      ]);

      if (orderResult.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Order not found', status: 404 } });
      }

      res.json({
        order: {
          ...orderResult.rows[0],
          items: itemsResult.rows
        }
      });
    } catch (error) {
      console.error('Get order by ID error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Cancel order (admin)
  async cancelOrder(req, res) {
    const client = await pool.connect();
    
    try {
      const { orderId } = req.params;

      await client.query('BEGIN');

      // Get order
      const order = await client.query(
        'SELECT * FROM orders WHERE id = $1',
        [orderId]
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
        [orderId]
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
        [orderId]
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

module.exports = adminController;

