const express = require('express');
const { query } = require('express-validator');
const youtubeController = require('../controllers/youtube.controller');
const authMiddleware = require('../middleware/auth.middleware');

const router = express.Router();

// Search YouTube videos (requires auth)
router.get('/search', authMiddleware, [
  query('q').notEmpty().trim(),
  query('maxResults').optional().isInt({ min: 1, max: 50 }),
  query('order').optional().isIn(['relevance', 'date', 'rating', 'viewCount', 'title']),
  query('videoDuration').optional().isIn(['any', 'short', 'medium', 'long']),
  query('publishedAfter').optional().isISO8601(),
], youtubeController.searchVideos);

// Get video details
router.get('/video/:videoId', authMiddleware, youtubeController.getVideoDetails);

module.exports = router;


