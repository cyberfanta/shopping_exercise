const { validationResult } = require('express-validator');
const pool = require('../config/database');

const SUPERADMIN_EMAIL = 'julioleon2004@gmail.com';

const userController = {
  // Get all users with pagination and filters
  async getAllUsers(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const page = parseInt(req.query.page) || 1;
      const limit = parseInt(req.query.limit) || 10;
      const offset = (page - 1) * limit;
      const { role, search } = req.query;

      let query = 'SELECT id, email, first_name, last_name, phone, role, is_active, created_at FROM users WHERE 1=1';
      const params = [];
      let paramCount = 1;

      if (role) {
        query += ` AND role = $${paramCount++}`;
        params.push(role);
      }

      if (search) {
        query += ` AND (email ILIKE $${paramCount++} OR first_name ILIKE $${paramCount++} OR last_name ILIKE $${paramCount++})`;
        params.push(`%${search}%`, `%${search}%`, `%${search}%`);
        paramCount += 2;
      }

      // Get total count
      const countQuery = query.replace('SELECT id, email, first_name, last_name, phone, role, is_active, created_at FROM users', 'SELECT COUNT(*)');
      const countResult = await pool.query(countQuery, params);
      const totalItems = parseInt(countResult.rows[0].count);

      // Add pagination and ordering
      query += ` ORDER BY created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
      params.push(limit, offset);

      const result = await pool.query(query, params);

      res.json({
        users: result.rows,
        pagination: {
          page,
          limit,
          totalItems,
          totalPages: Math.ceil(totalItems / limit)
        }
      });
    } catch (error) {
      console.error('Get all users error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get single user
  async getUserById(req, res) {
    try {
      const { id } = req.params;

      const result = await pool.query(
        'SELECT id, email, first_name, last_name, phone, role, is_active, created_at FROM users WHERE id = $1',
        [id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'User not found', status: 404 } });
      }

      res.json({ user: result.rows[0] });
    } catch (error) {
      console.error('Get user by id error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Update user
  async updateUser(req, res) {
    try {
      const { id } = req.params;
      const { first_name, last_name, phone, role, is_active } = req.body;

      // Check if trying to modify superadmin
      const userCheck = await pool.query('SELECT email FROM users WHERE id = $1', [id]);
      
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ error: { message: 'User not found', status: 404 } });
      }

      if (userCheck.rows[0].email === SUPERADMIN_EMAIL && req.user.email !== SUPERADMIN_EMAIL) {
        return res.status(403).json({ 
          error: { 
            message: 'Cannot modify superadmin user', 
            status: 403 
          } 
        });
      }

      // Only superadmin can assign admin/superadmin roles
      if (role && ['admin', 'superadmin'].includes(role) && req.user.role !== 'superadmin') {
        return res.status(403).json({ 
          error: { 
            message: 'Only superadmin can assign admin privileges', 
            status: 403 
          } 
        });
      }

      const updates = [];
      const values = [];
      let paramCount = 1;

      if (first_name) {
        updates.push(`first_name = $${paramCount++}`);
        values.push(first_name);
      }
      if (last_name) {
        updates.push(`last_name = $${paramCount++}`);
        values.push(last_name);
      }
      if (phone !== undefined) {
        updates.push(`phone = $${paramCount++}`);
        values.push(phone);
      }
      if (role && req.user.role === 'superadmin') {
        updates.push(`role = $${paramCount++}`);
        values.push(role);
      }
      if (is_active !== undefined && userCheck.rows[0].email !== SUPERADMIN_EMAIL) {
        updates.push(`is_active = $${paramCount++}`);
        values.push(is_active);
      }

      if (updates.length === 0) {
        return res.status(400).json({ error: { message: 'No fields to update', status: 400 } });
      }

      values.push(id);
      const query = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING id, email, first_name, last_name, phone, role, is_active`;

      const result = await pool.query(query, values);

      res.json({ message: 'User updated successfully', user: result.rows[0] });
    } catch (error) {
      console.error('Update user error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Delete user
  async deleteUser(req, res) {
    try {
      const { id } = req.params;

      // Check if trying to delete superadmin
      const userCheck = await pool.query('SELECT email FROM users WHERE id = $1', [id]);
      
      if (userCheck.rows.length === 0) {
        return res.status(404).json({ error: { message: 'User not found', status: 404 } });
      }

      if (userCheck.rows[0].email === SUPERADMIN_EMAIL) {
        return res.status(403).json({ 
          error: { 
            message: 'Cannot delete superadmin user', 
            status: 403 
          } 
        });
      }

      // Soft delete
      await pool.query('UPDATE users SET is_active = false WHERE id = $1', [id]);

      res.json({ message: 'User deleted successfully' });
    } catch (error) {
      console.error('Delete user error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  }
};

module.exports = userController;


