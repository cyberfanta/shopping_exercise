const { validationResult } = require('express-validator');
const pool = require('../config/database');

const productController = {
  // Get all products with pagination and filters
  async getAllProducts(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const { category_id, search } = req.query;

      let query = `
        SELECT p.*, c.name as category_name 
        FROM products p 
        LEFT JOIN categories c ON p.category_id = c.id 
        WHERE p.is_active = true
      `;
      const params = [];
      let paramCount = 1;

      if (category_id) {
        query += ` AND p.category_id = $${paramCount++}`;
        params.push(category_id);
      }

      if (search) {
        query += ` AND (p.name ILIKE $${paramCount++} OR p.description ILIKE $${paramCount++})`;
        params.push(`%${search}%`, `%${search}%`);
        paramCount++;
      }

      // Get total count
      const countQuery = query.replace('SELECT p.*, c.name as category_name', 'SELECT COUNT(*)');
      const countResult = await pool.query(countQuery, params);
      const totalItems = parseInt(countResult.rows[0].count);

      // Add pagination
      query += ` ORDER BY p.created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
      params.push(limit, offset);

      const result = await pool.query(query, params);

      res.json({
        products: result.rows,
        pagination: {
          page,
          limit,
          totalItems,
          totalPages: Math.ceil(totalItems / limit)
        }
      });
    } catch (error) {
      console.error('Get all products error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get single product
  async getProductById(req, res) {
    try {
      const { id } = req.params;

      const result = await pool.query(
        `SELECT p.*, c.name as category_name 
         FROM products p 
         LEFT JOIN categories c ON p.category_id = c.id 
         WHERE p.id = $1 AND p.is_active = true`,
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Product not found', status: 404 } });
      }

      res.json({ product: result.rows[0] });
    } catch (error) {
      console.error('Get product by id error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Create product
  async createProduct(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { 
        name, 
        description, 
        price, 
        discount_price, 
        stock, 
        youtube_video_id, 
        youtube_thumbnail, 
        youtube_duration,
        youtube_channel_id,
        youtube_channel_name,
        image_url, 
        images 
      } = req.body;

      let category_id = null;

      // If it's a YouTube video, create/get category by channel
      if (youtube_channel_id && youtube_channel_name) {
        category_id = await getOrCreateCategoryByChannel(youtube_channel_id, youtube_channel_name);
      }

      const result = await pool.query(
        `INSERT INTO products (
          category_id, name, description, price, discount_price, stock, 
          youtube_video_id, youtube_thumbnail, youtube_duration,
          image_url, images
        ) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) 
         RETURNING *`,
        [
          category_id, 
          name, 
          description || null, 
          price, 
          discount_price || null, 
          stock || 999, // YouTube videos have unlimited stock by default
          youtube_video_id || null,
          youtube_thumbnail || null,
          youtube_duration || null,
          image_url || null, 
          JSON.stringify(images || [])
        ]
      );

      res.status(201).json({ message: 'Product created successfully', product: result.rows[0] });
    } catch (error) {
      console.error('Create product error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Create multiple products from YouTube videos
  async createMultipleProducts(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { products } = req.body; // Array of products

      if (!Array.isArray(products) || products.length === 0) {
        return res.status(400).json({ error: { message: 'products must be a non-empty array', status: 400 } });
      }

      const createdProducts = [];
      const errors_list = [];

      for (const product of products) {
        try {
          let category_id = null;

          // Create/get category by channel
          if (product.youtube_channel_id && product.youtube_channel_name) {
            category_id = await getOrCreateCategoryByChannel(
              product.youtube_channel_id, 
              product.youtube_channel_name
            );
          }

          const result = await pool.query(
            `INSERT INTO products (
              category_id, name, description, price, discount_price, stock,
              youtube_video_id, youtube_thumbnail, youtube_duration,
              image_url
            ) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) 
            RETURNING *`,
            [
              category_id,
              product.name,
              product.description || null,
              product.price,
              product.discount_price || null,
              product.stock || 999,
              product.youtube_video_id || null,
              product.youtube_thumbnail || null,
              product.youtube_duration || null,
              product.image_url || null,
            ]
          );

          createdProducts.push(result.rows[0]);
        } catch (error) {
          errors_list.push({ 
            product: product.name, 
            error: error.message 
          });
        }
      }

      res.status(201).json({
        message: `${createdProducts.length} products created successfully`,
        products: createdProducts,
        errors: errors_list.length > 0 ? errors_list : undefined
      });
    } catch (error) {
      console.error('Create multiple products error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Update product
  async updateProduct(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { id } = req.params;
      const { category_id, name, description, price, discount_price, stock, image_url, images, is_active } = req.body;

      const updates = [];
      const values = [];
      let paramCount = 1;

      if (category_id !== undefined) {
        updates.push(`category_id = $${paramCount++}`);
        values.push(category_id);
      }
      if (name) {
        updates.push(`name = $${paramCount++}`);
        values.push(name);
      }
      if (description !== undefined) {
        updates.push(`description = $${paramCount++}`);
        values.push(description);
      }
      if (price !== undefined) {
        updates.push(`price = $${paramCount++}`);
        values.push(price);
      }
      if (discount_price !== undefined) {
        updates.push(`discount_price = $${paramCount++}`);
        values.push(discount_price);
      }
      if (stock !== undefined) {
        updates.push(`stock = $${paramCount++}`);
        values.push(stock);
      }
      if (image_url !== undefined) {
        updates.push(`image_url = $${paramCount++}`);
        values.push(image_url);
      }
      if (images) {
        updates.push(`images = $${paramCount++}`);
        values.push(JSON.stringify(images));
      }
      if (is_active !== undefined) {
        updates.push(`is_active = $${paramCount++}`);
        values.push(is_active);
      }

      if (updates.length === 0) {
        return res.status(400).json({ error: { message: 'No fields to update', status: 400 } });
      }

      values.push(id);
      const query = `UPDATE products SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;

      const result = await pool.query(query, values);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Product not found', status: 404 } });
      }

      res.json({ message: 'Product updated successfully', product: result.rows[0] });
    } catch (error) {
      console.error('Update product error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Delete product (soft delete)
  async deleteProduct(req, res) {
    try {
      const { id } = req.params;

      const result = await pool.query(
        'UPDATE products SET is_active = false WHERE id = $1 RETURNING id',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Product not found', status: 404 } });
      }

      res.json({ message: 'Product deleted successfully' });
    } catch (error) {
      console.error('Delete product error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  }
};

// Helper function to get or create category by YouTube channel
async function getOrCreateCategoryByChannel(channelId, channelName) {
  try {
    // Try to find existing category by channel name
    const existing = await pool.query(
      'SELECT id FROM categories WHERE name = $1',
      [channelName]
    );

    if (existing.rows.length > 0) {
      return existing.rows[0].id;
    }

    // Create new category for this channel
    const newCategory = await pool.query(
      `INSERT INTO categories (name, description, is_active) 
       VALUES ($1, $2, true) 
       RETURNING id`,
      [
        channelName,
        `Videos del canal: ${channelName}`
      ]
    );

    return newCategory.rows[0].id;
  } catch (error) {
    console.error('Error creating/getting category:', error);
    return null;
  }
}

module.exports = productController;

