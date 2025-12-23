const express = require('express');
const { body } = require('express-validator');
const categoryController = require('../controllers/category.controller');
const authMiddleware = require('../middleware/auth.middleware');
const adminMiddleware = require('../middleware/admin.middleware');

const router = express.Router();

// Get all categories
router.get('/', categoryController.getAllCategories);

// Get single category
router.get('/:id', categoryController.getCategoryById);

// Create category (protected - admin/superadmin only)
router.post('/', authMiddleware, adminMiddleware, [
  body('name').notEmpty().trim(),
  body('description').optional().trim()
], categoryController.createCategory);

// Update category (protected - admin/superadmin only)
router.put('/:id', authMiddleware, adminMiddleware, [
  body('name').optional().trim(),
  body('description').optional().trim()
], categoryController.updateCategory);

// Delete category (protected - admin/superadmin only)
router.delete('/:id', authMiddleware, adminMiddleware, categoryController.deleteCategory);

module.exports = router;

