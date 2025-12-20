const express = require('express');
const { body } = require('express-validator');
const orderController = require('../controllers/order.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

// All order routes are protected
router.use(authMiddleware);

// Get user's orders
router.get('/', orderController.getUserOrders);

// Get single order
router.get('/:id', orderController.getOrderById);

// Create order from cart (checkout)
router.post('/', [
  body('payment_method').notEmpty().trim(),
  body('shipping_address').isObject(),
  body('shipping_address.street').notEmpty().trim(),
  body('shipping_address.city').notEmpty().trim(),
  body('shipping_address.state').notEmpty().trim(),
  body('shipping_address.zip').notEmpty().trim(),
  body('shipping_address.country').notEmpty().trim()
], orderController.createOrder);

// Simulate payment (for development)
router.post('/:id/pay', orderController.simulatePayment);

// Cancel order
router.post('/:id/cancel', orderController.cancelOrder);

module.exports = router;

