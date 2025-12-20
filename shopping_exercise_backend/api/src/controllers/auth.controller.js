const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { validationResult } = require('express-validator');
const pool = require('../config/database');
const emailService = require('../services/email.service');

const authController = {
  // Register new user
  async register(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, first_name, last_name, phone } = req.body;

      // Check if user exists
      const userExists = await pool.query('SELECT id FROM users WHERE email = $1', [email]);
      if (userExists.rows.length > 0) {
        return res.status(409).json({ error: { message: 'Email already registered', status: 409 } });
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);

      // Create user
      const result = await pool.query(
        'INSERT INTO users (email, password_hash, first_name, last_name, phone) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, first_name, last_name, phone, created_at',
        [email, password_hash, first_name, last_name, phone || null]
      );

      const user = result.rows[0];

      // Generate JWT
      const token = jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN }
      );

      res.status(201).json({
        message: 'User registered successfully',
        user,
        token
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Login
  async login(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      // Find user
      const result = await pool.query(
        'SELECT id, email, password_hash, first_name, last_name, phone, is_active FROM users WHERE email = $1',
        [email]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: { message: 'Invalid credentials', status: 401 } });
      }

      const user = result.rows[0];

      if (!user.is_active) {
        return res.status(403).json({ error: { message: 'Account is deactivated', status: 403 } });
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({ error: { message: 'Invalid credentials', status: 401 } });
      }

      // Generate JWT
      const token = jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN }
      );

      delete user.password_hash;

      res.json({
        message: 'Login successful',
        user,
        token
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Forgot password
  async forgotPassword(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email } = req.body;

      // Find user
      const result = await pool.query('SELECT id, email, first_name FROM users WHERE email = $1', [email]);
      
      if (result.rows.length === 0) {
        // Don't reveal if email exists or not
        return res.json({ message: 'If the email exists, a reset link has been sent' });
      }

      const user = result.rows[0];

      // Generate reset token
      const resetToken = crypto.randomBytes(32).toString('hex');
      const expiresAt = new Date(Date.now() + 3600000); // 1 hour

      // Save token
      await pool.query(
        'INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
        [user.id, resetToken, expiresAt]
      );

      // Send email
      const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;
      await emailService.sendPasswordResetEmail(user.email, user.first_name, resetUrl);

      res.json({ message: 'If the email exists, a reset link has been sent' });
    } catch (error) {
      console.error('Forgot password error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Reset password
  async resetPassword(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { token, password } = req.body;

      // Find valid token
      const result = await pool.query(
        'SELECT user_id FROM password_reset_tokens WHERE token = $1 AND expires_at > NOW() AND used = false',
        [token]
      );

      if (result.rows.length === 0) {
        return res.status(400).json({ error: { message: 'Invalid or expired token', status: 400 } });
      }

      const { user_id } = result.rows[0];

      // Hash new password
      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);

      // Update password
      await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [password_hash, user_id]);

      // Mark token as used
      await pool.query('UPDATE password_reset_tokens SET used = true WHERE token = $1', [token]);

      res.json({ message: 'Password reset successfully' });
    } catch (error) {
      console.error('Reset password error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Get current user
  async getCurrentUser(req, res) {
    try {
      const result = await pool.query(
        'SELECT id, email, first_name, last_name, phone, created_at FROM users WHERE id = $1',
        [req.user.id]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'User not found', status: 404 } });
      }

      res.json({ user: result.rows[0] });
    } catch (error) {
      console.error('Get current user error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Update profile
  async updateProfile(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { first_name, last_name, phone } = req.body;
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

      if (updates.length === 0) {
        return res.status(400).json({ error: { message: 'No fields to update', status: 400 } });
      }

      values.push(req.user.id);
      const query = `UPDATE users SET ${updates.join(', ')} WHERE id = $${paramCount} RETURNING id, email, first_name, last_name, phone`;

      const result = await pool.query(query, values);

      res.json({ message: 'Profile updated successfully', user: result.rows[0] });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  },

  // Change password
  async changePassword(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { current_password, new_password } = req.body;

      // Get user with password
      const result = await pool.query('SELECT password_hash FROM users WHERE id = $1', [req.user.id]);
      
      if (result.rows.length === 0) {
        return res.status(404).json({ error: { message: 'User not found', status: 404 } });
      }

      // Verify current password
      const isValid = await bcrypt.compare(current_password, result.rows[0].password_hash);
      if (!isValid) {
        return res.status(401).json({ error: { message: 'Current password is incorrect', status: 401 } });
      }

      // Hash new password
      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(new_password, salt);

      // Update password
      await pool.query('UPDATE users SET password_hash = $1 WHERE id = $2', [password_hash, req.user.id]);

      res.json({ message: 'Password changed successfully' });
    } catch (error) {
      console.error('Change password error:', error);
      res.status(500).json({ error: { message: 'Internal server error', status: 500 } });
    }
  }
};

module.exports = authController;

