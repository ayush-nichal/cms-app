const express = require('express');
const userController = require('../controllers/user.controller');
const { requireAuth, requireAdmin } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');

const router = express.Router();

router.use(requireAuth, requireAdmin);

router.get('/', asyncHandler(userController.getAll));
router.post('/', asyncHandler(userController.create));
router.get('/:id', asyncHandler(userController.getById));
router.put('/:id', asyncHandler(userController.update));
router.delete('/:id', asyncHandler(userController.delete));

router.get('/:id/assignments', asyncHandler(userController.getAssignments));
router.post('/:id/assignments', asyncHandler(userController.addAssignment));
router.delete('/:id/assignments/:channelId', asyncHandler(userController.removeAssignment));
router.post('/:id/send-reset-link', asyncHandler(userController.sendResetLink));

module.exports = router;
