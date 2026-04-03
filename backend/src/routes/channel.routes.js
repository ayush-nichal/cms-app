const express = require('express');
const channelController = require('../controllers/channel.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.use(requireAuth, requireAdmin);

router.post('/', asyncHandler(channelController.create));
router.get('/:id', asyncHandler(channelController.getById));
router.put('/:id', asyncHandler(channelController.update));
router.delete('/:id', asyncHandler(channelController.delete));

module.exports = router;
