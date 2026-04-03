const express = require('express');
const platformController = require('../controllers/platform.controller');
const channelService = require('../services/channel.service');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.use(requireAuth, requireAdmin);

router.get('/', asyncHandler(platformController.getAll));
router.post('/', asyncHandler(platformController.create));
router.get('/:id', asyncHandler(platformController.getById));
router.put('/:id', asyncHandler(platformController.update));
router.delete('/:id', asyncHandler(platformController.delete));

router.get('/:id/channels', asyncHandler(async (req, res, next) => {
  try {
    const channels = await channelService.getByPlatform(req.params.id);
    res.status(200).json(channels);
  } catch (error) { next(error); }
}));

module.exports = router;
