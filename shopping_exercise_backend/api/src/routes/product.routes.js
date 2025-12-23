const express = require('express');
const { body, query } = require('express-validator');
const productController = require('../controllers/product.controller');
const authMiddleware = require('../middleware/auth.middleware');
const adminMiddleware = require('../middleware/admin.middleware');

const router = express.Router();

// Get all products (with pagination and filters)
router.get('/', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('category_id').optional().isUUID(),
  query('search').optional().trim()
], productController.getAllProducts);

// Get single product
router.get('/:id', productController.getProductById);

// Create product (protected - admin/superadmin only)
router.post('/', authMiddleware, adminMiddleware, [
  body('name').notEmpty().trim(),
  body('description').optional().trim(),
  body('price').isFloat({ min: 0 }),
  body('stock').optional().isInt({ min: 0 }),
  body('youtube_video_id').optional().trim(),
  body('youtube_channel_id').optional().trim(),
  body('youtube_channel_name').optional().trim(),
], productController.createProduct);

// Create multiple products (protected - admin/superadmin only)
router.post('/bulk', authMiddleware, adminMiddleware, [
  body('products').isArray({ min: 1 }),
  body('products.*.name').notEmpty().trim(),
  body('products.*.price').isFloat({ min: 0 }),
], productController.createMultipleProducts);

// Update product (protected - admin/superadmin only)
router.put('/:id', authMiddleware, adminMiddleware, [
  body('name').optional().trim(),
  body('description').optional().trim(),
  body('price').optional().isFloat({ min: 0 }),
  body('stock').optional().isInt({ min: 0 }),
  body('category_id').optional().isUUID()
], productController.updateProduct);

// Delete product (protected - admin/superadmin only)
router.delete('/:id', authMiddleware, adminMiddleware, productController.deleteProduct);

module.exports = router;

