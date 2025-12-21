const express = require('express');
const { query, param } = require('express-validator');
const authMiddleware = require('../middleware/auth.middleware');
const adminMiddleware = require('../middleware/admin.middleware');
const adminController = require('../controllers/admin.controller');

const router = express.Router();

// All admin routes require authentication and admin role
router.use(authMiddleware);
router.use(adminMiddleware);

// Cart routes
router.get('/carts', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 })
], adminController.getAllCarts);

router.get('/carts/:userId', [
  param('userId').isUUID()
], adminController.getCartByUserId);

router.delete('/carts/:userId', [
  param('userId').isUUID()
], adminController.clearUserCart);

router.get('/carts-stats', adminController.getCartStats);

// Order routes
router.get('/orders', [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('status').optional().isIn(['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'])
], adminController.getAllOrders);

router.get('/orders/:orderId', [
  param('orderId').isUUID()
], adminController.getOrderById);

router.delete('/orders/:orderId', [
  param('orderId').isUUID()
], adminController.cancelOrder);

module.exports = router;

