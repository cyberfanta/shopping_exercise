const express = require('express');
const { body } = require('express-validator');
const cartController = require('../controllers/cart.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

// All cart routes are protected
router.use(authMiddleware);

// Get user's cart
router.get('/', cartController.getCart);

// Add item to cart
router.post('/items', [
  body('product_id').isUUID(),
  body('quantity').isInt({ min: 1 })
], cartController.addItem);

// Update cart item quantity
router.put('/items/:item_id', [
  body('quantity').isInt({ min: 1 })
], cartController.updateItem);

// Remove item from cart
router.delete('/items/:item_id', cartController.removeItem);

// Clear cart
router.delete('/', cartController.clearCart);

module.exports = router;

