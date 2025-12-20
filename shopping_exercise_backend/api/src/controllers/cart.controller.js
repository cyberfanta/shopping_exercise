const { validationResult } = require('express-validator');
const pool = require('../config/database');

const cartController = {
  // Get user's cart
  async getCart(req, res) {
    try {
      const userId = req.user.id;

      // Get or create cart
      let cart = await pool.query('SELECT * FROM carts WHERE user_id = $1', [userId]);
      
      if (cart.rows.length === 0) {
        const newCart = await pool.query(
          'INSERT INTO carts (user_id) VALUES ($1) RETURNING *',
          [userId]
        );
        cart = newCart;
      }

      const cartId = cart.rows[0].id;

      // Get cart items with product details
      const items = await pool.query(
        `SELECT 
          ci.id,
          ci.quantity,
          ci.price,
          ci.quantity * ci.price as subtotal,
          p.id as product_id,
          p.name as product_name,
          p.description as product_description,
          p.image_url,
          p.stock
        FROM cart_items ci
        JOIN products p ON ci.product_id = p.id
        WHERE ci.cart_id = $1 AND p.is_active = true`,
        [cartId]
      );

      const total = items.rows.reduce((sum, item) => sum + parseFloat(item.subtotal), 0);

      res.json({
        cart: {
          id: cartId,
          items: items.rows,
          total: total.toFixed(2)
        }
      });
    } catch (error) {
      console.error('Get cart error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Add item to cart
  async addItem(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { product_id, quantity } = req.body;

      // Get product and check stock
      const product = await pool.query(
        'SELECT id, name, price, stock, is_active FROM products WHERE id = $1',
        [product_id]
      );

      if (product.rows.length === 0 || !product.rows[0].is_active) {
        return res.status(404).json({ error: { message: 'Product not found', status: 404 } });
      }

      if (product.rows[0].stock < quantity) {
        return res.status(400).json({ error: { message: 'Insufficient stock', status: 400 } });
      }

      // Get or create cart
      let cart = await pool.query('SELECT id FROM carts WHERE user_id = $1', [userId]);
      
      if (cart.rows.length === 0) {
        cart = await pool.query('INSERT INTO carts (user_id) VALUES ($1) RETURNING id', [userId]);
      }

      const cartId = cart.rows[0].id;

      // Check if item already in cart
      const existingItem = await pool.query(
        'SELECT id, quantity FROM cart_items WHERE cart_id = $1 AND product_id = $2',
        [cartId, product_id]
      );

      if (existingItem.rows.length > 0) {
        // Update quantity
        const newQuantity = existingItem.rows[0].quantity + quantity;
        
        if (product.rows[0].stock < newQuantity) {
          return res.status(400).json({ error: { message: 'Insufficient stock', status: 400 } });
        }

        await pool.query(
          'UPDATE cart_items SET quantity = $1 WHERE id = $2',
          [newQuantity, existingItem.rows[0].id]
        );
      } else {
        // Add new item
        await pool.query(
          'INSERT INTO cart_items (cart_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)',
          [cartId, product_id, quantity, product.rows[0].price]
        );
      }

      res.json({ message: 'Item added to cart successfully' });
    } catch (error) {
      console.error('Add item error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Update cart item quantity
  async updateItem(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { item_id } = req.params;
      const { quantity } = req.body;

      // Verify item belongs to user's cart
      const item = await pool.query(
        `SELECT ci.id, ci.product_id, p.stock 
         FROM cart_items ci
         JOIN carts c ON ci.cart_id = c.id
         JOIN products p ON ci.product_id = p.id
         WHERE ci.id = $1 AND c.user_id = $2`,
        [item_id, userId]
      );

      if (item.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Cart item not found', status: 404 } });
      }

      if (item.rows[0].stock < quantity) {
        return res.status(400).json({ error: { message: 'Insufficient stock', status: 400 } });
      }

      await pool.query('UPDATE cart_items SET quantity = $1 WHERE id = $2', [quantity, item_id]);

      res.json({ message: 'Cart item updated successfully' });
    } catch (error) {
      console.error('Update item error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Remove item from cart
  async removeItem(req, res) {
    try {
      const userId = req.user.id;
      const { item_id } = req.params;

      // Verify item belongs to user's cart
      const result = await pool.query(
        `DELETE FROM cart_items ci
         USING carts c
         WHERE ci.cart_id = c.id
         AND ci.id = $1
         AND c.user_id = $2
         RETURNING ci.id`,
        [item_id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Cart item not found', status: 404 } });
      }

      res.json({ message: 'Item removed from cart successfully' });
    } catch (error) {
      console.error('Remove item error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Clear cart
  async clearCart(req, res) {
    try {
      const userId = req.user.id;

      await pool.query(
        `DELETE FROM cart_items
         WHERE cart_id IN (SELECT id FROM carts WHERE user_id = $1)`,
        [userId]
      );

      res.json({ message: 'Cart cleared successfully' });
    } catch (error) {
      console.error('Clear cart error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  }
};

module.exports = cartController;

