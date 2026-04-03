const express = require('express');
const mediaController = require('../controllers/media.controller');
const { requireAuth } = require('../middleware/auth');
const asyncHandler = require('../utils/asyncHandler');
const multer = require('multer');

// Configure multer (memory storage, 50MB limit)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }
});

const router = express.Router();

router.use(requireAuth);

router.post('/upload', upload.single('file'), asyncHandler(mediaController.upload));
router.delete('/', asyncHandler(mediaController.delete));

module.exports = router;
