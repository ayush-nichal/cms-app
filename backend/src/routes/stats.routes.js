const express = require('express');
const statsController = require('../controllers/stats.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.use(requireAuth, requireAdmin);

router.get('/overview', asyncHandler(statsController.getOverview));
router.get('/platform/:id', asyncHandler(statsController.getPlatformStats));

module.exports = router;
