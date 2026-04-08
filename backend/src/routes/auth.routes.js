const express = require('express');
const authController = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.post('/login', asyncHandler(authController.login));
router.post('/forgot-password', asyncHandler(authController.forgotPassword));
router.post('/logout', requireAuth, asyncHandler(authController.logout));
router.get('/me', requireAuth, asyncHandler(authController.me));
router.post('/reset-password', asyncHandler(authController.resetPassword));

module.exports = router;
