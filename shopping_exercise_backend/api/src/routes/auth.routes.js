const express = require('express');
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

// Register
router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('first_name').notEmpty().trim(),
  body('last_name').notEmpty().trim()
], authController.register);

// Login
router.post('/login', [
  body('email')
    .isEmail()
    .withMessage('Debe proporcionar un email válido')
    .normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('La contraseña es requerida')
], authController.login);

// Request password reset
router.post('/forgot-password', [
  body('email').isEmail().normalizeEmail()
], authController.forgotPassword);

// Reset password
router.post('/reset-password', [
  body('token').notEmpty(),
  body('password').isLength({ min: 6 })
], authController.resetPassword);

// Get current user (protected)
router.get('/me', authMiddleware, authController.getCurrentUser);

// Update profile (protected)
router.put('/profile', authMiddleware, [
  body('first_name').optional().trim(),
  body('last_name').optional().trim(),
  body('phone').optional().trim()
], authController.updateProfile);

// Change password (protected)
router.post('/change-password', authMiddleware, [
  body('current_password').notEmpty(),
  body('new_password').isLength({ min: 6 })
], authController.changePassword);

module.exports = router;

