const express = require('express');
const router = express.Router();
const { getLatestVersion } = require('../controllers/version.controller');

// GET /api/version — public, no auth required
router.get('/', getLatestVersion);

module.exports = router;
