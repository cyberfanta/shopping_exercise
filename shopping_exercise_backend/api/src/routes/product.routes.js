const express = require('express');
const { body, query } = require('express-validator');
const productController = require('../controllers/product.controller');
const authMiddleware = require('../middleware/auth.middleware');

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

// Create product (protected)
router.post('/', authMiddleware, [
  body('name').notEmpty().trim(),
  body('description').optional().trim(),
  body('price').isFloat({ min: 0 }),
  body('stock').isInt({ min: 0 }),
  body('category_id').optional().isUUID()
], productController.createProduct);

// Update product (protected)
router.put('/:id', authMiddleware, [
  body('name').optional().trim(),
  body('description').optional().trim(),
  body('price').optional().isFloat({ min: 0 }),
  body('stock').optional().isInt({ min: 0 }),
  body('category_id').optional().isUUID()
], productController.updateProduct);

// Delete product (protected)
router.delete('/:id', authMiddleware, productController.deleteProduct);

module.exports = router;

