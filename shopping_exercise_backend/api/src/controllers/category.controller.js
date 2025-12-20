const { validationResult } = require('express-validator');
const pool = require('../config/database');

const categoryController = {
  // Get all categories
  async getAllCategories(req, res) {
    try {
      const result = await pool.query(
        'SELECT * FROM categories WHERE is_active = true ORDER BY name'
      );

      res.json({ categories: result.rows });
    } catch (error) {
      console.error('Get all categories error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get single category
  async getCategoryById(req, res) {
    try {
      const { id } = req.params;

      const result = await pool.query(
        'SELECT * FROM categories WHERE id = $1 AND is_active = true',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Category not found', status: 404 } });
      }

      res.json({ category: result.rows[0] });
    } catch (error) {
      console.error('Get category by id error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Create category
  async createCategory(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { name, description, image_url } = req.body;

      const result = await pool.query(
        'INSERT INTO categories (name, description, image_url) VALUES ($1, $2, $3) RETURNING *',
        [name, description || null, image_url || null]
      );

      res.status(201).json({ message: 'Category created successfully', category: result.rows[0] });
    } catch (error) {
      console.error('Create category error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Update category
  async updateCategory(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { id } = req.params;
      const { name, description, image_url, is_active } = req.body;

      const updates = [];
      const values = [];
      let paramCount = 1;

      if (name) {
        updates.push(`name = $${paramCount++}`);
        values.push(name);
      }
      if (description !== undefined) {
        updates.push(`description = $${paramCount++}`);
        values.push(description);
      }
      if (image_url !== undefined) {
        updates.push(`image_url = $${paramCount++}`);
        values.push(image_url);
      }
      if (is_active !== undefined) {
        updates.push(`is_active = $${paramCount++}`);
        values.push(is_active);
      }

      if (updates.length === 0) {
        return res.status(400).json({ error: { message: 'No fields to update', status: 400 } });
      }

      values.push(id);
      const query = `UPDATE categories SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING *`;

      const result = await pool.query(query, values);

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Category not found', status: 404 } });
      }

      res.json({ message: 'Category updated successfully', category: result.rows[0] });
    } catch (error) {
      console.error('Update category error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Delete category
  async deleteCategory(req, res) {
    try {
      const { id } = req.params;

      const result = await pool.query(
        'UPDATE categories SET is_active = false WHERE id = $1 RETURNING id',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'Category not found', status: 404 } });
      }

      res.json({ message: 'Category deleted successfully' });
    } catch (error) {
      console.error('Delete category error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  }
};

module.exports = categoryController;

