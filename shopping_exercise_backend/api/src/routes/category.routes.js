const express = require('express');
const { body } = require('express-validator');
const categoryController = require('../controllers/category.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

// Get all categories
router.get('/', categoryController.getAllCategories);

// Get single category
router.get('/:id', categoryController.getCategoryById);

// Create category (protected)
router.post('/', authMiddleware, [
  body('name').notEmpty().trim(),
  body('description').optional().trim()
], categoryController.createCategory);

// Update category (protected)
router.put('/:id', authMiddleware, [
  body('name').optional().trim(),
  body('description').optional().trim()
], categoryController.updateCategory);

// Delete category (protected)
router.delete('/:id', authMiddleware, categoryController.deleteCategory);

module.exports = router;

