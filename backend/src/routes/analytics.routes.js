const express = require('express');
const analyticsController = require('../controllers/analytics.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.use(requireAuth, requireAdmin);

// Global Dashboard Analytics
router.get('/dashboard/summary', asyncHandler(analyticsController.getDashboardSummary));
router.get('/dashboard/schedules-list', asyncHandler(analyticsController.getSchedulesList));

// Platform level routes
router.get('/platform/:id/pipeline', asyncHandler(analyticsController.getPipelineForecast));
router.get('/platform/:id/workload', asyncHandler(analyticsController.getWorkloadDistribution));
router.get('/platform/:id/content-mix', asyncHandler(analyticsController.getPlatformContentMix));
router.get('/platform/:id/schedules', asyncHandler(analyticsController.getRecentSchedulesTotal));

// Channel level routes
router.get('/channel/:id/heatmap', asyncHandler(analyticsController.getCoverageHeatmap));
router.get('/channel/:id/lead-time', asyncHandler(analyticsController.getLeadTime));
router.get('/channel/:id/content-mix', asyncHandler(analyticsController.getChannelContentMix));
router.get('/channel/:id/trend', asyncHandler(analyticsController.getChannelTrend));

module.exports = router;
