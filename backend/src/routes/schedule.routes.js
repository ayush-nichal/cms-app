const express = require('express');
const scheduleController = require('../controllers/schedule.controller');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.use(requireAuth);

router.get('/', asyncHandler(scheduleController.getAllByChannel));
router.post('/', asyncHandler(scheduleController.create));
router.get('/:id', asyncHandler(scheduleController.getById));
router.put('/:id', asyncHandler(scheduleController.update));
router.delete('/:id', asyncHandler(scheduleController.delete));
router.patch('/:id/status', asyncHandler(scheduleController.updateStatus));

module.exports = router;
