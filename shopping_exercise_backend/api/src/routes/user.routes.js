const express = require('express');
const { query } = require('express-validator');
const userController = require('../controllers/user.controller');
const authMiddleware = require('../middleware/auth.middleware');
const adminMiddleware = require('../middleware/admin.middleware');

const router = express.Router();

// All user management routes require admin privileges
router.use(authMiddleware);
router.use(adminMiddleware);

// Get all users with pagination
router.get('/', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('role').optional().isIn(['user', 'admin', 'superadmin']),
  query('search').optional().trim()
], userController.getAllUsers);

// Get single user
router.get('/:id', userController.getUserById);

// Update user (admin can change role, but not delete superadmin)
router.put('/:id', userController.updateUser);

// Delete user (cannot delete superadmin)
router.delete('/:id', userController.deleteUser);

module.exports = router;

