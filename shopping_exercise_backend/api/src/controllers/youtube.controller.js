const { validationResult } = require('express-validator');
const axios = require('axios');

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY || '';
const YOUTUBE_API_BASE = 'https://www.googleapis.com/youtube/v3';

const youtubeController = {
  // Search YouTube videos with filters
  async searchVideos(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { 
        q, 
        maxResults = 10,
        order = 'relevance', // relevance, date, rating, viewCount, title
        videoDuration = 'any', // any, short (<4min), medium (4-20min), long (>20min)
        publishedAfter, // ISO 8601 format
      } = req.query;

      if (!YOUTUBE_API_KEY) {
        return res.status(500).json({ 
          error: { 
            message: 'YouTube API key not configured. Please add YOUTUBE_API_KEY to .env file.',
            status: 500 
          } 
        });
      }

      const params = {
        key: YOUTUBE_API_KEY,
        q,
        part: 'snippet',
        type: 'video',
        maxResults: Math.min(parseInt(maxResults), 50),
        videoEmbeddable: true,
        order,
        videoDuration,
      };

      if (publishedAfter) {
        params.publishedAfter = publishedAfter;
      }

      const response = await axios.get(`${YOUTUBE_API_BASE}/search`, { params });

      // Get video IDs to fetch statistics
      const videoIds = response.data.items.map(item => item.id.videoId).join(',');

      // Get video statistics (views, likes, duration)
      const statsResponse = await axios.get(`${YOUTUBE_API_BASE}/videos`, {
        params: {
          key: YOUTUBE_API_KEY,
          id: videoIds,
          part: 'statistics,contentDetails',
        }
      });

      // Merge search results with statistics
      const videos = response.data.items.map((item, index) => {
        const stats = statsResponse.data.items.find(s => s.id === item.id.videoId);
        const viewCount = parseInt(stats?.statistics?.viewCount || '0');
        
        return {
          videoId: item.id.videoId,
          title: item.snippet.title,
          description: item.snippet.description,
          thumbnail: item.snippet.thumbnails.high?.url || item.snippet.thumbnails.medium.url,
          channelId: item.snippet.channelId,
          channelTitle: item.snippet.channelTitle,
          publishedAt: item.snippet.publishedAt,
          viewCount: viewCount,
          likeCount: parseInt(stats?.statistics?.likeCount || '0'),
          duration: stats?.contentDetails?.duration || 'PT0S',
          // Calculate suggested price based on views
          suggestedPrice: calculatePriceFromViews(viewCount),
        };
      });

      res.json({ videos });
    } catch (error) {
      console.error('YouTube search error:', error.response?.data || error.message);
      
      res.status(500).json({ 
        error: { 
          message: 'Error searching videos. Check your YouTube API key and quota.',
          details: error.response?.data?.error?.message || error.message,
          status: 500 
        } 
      });
    }
  },

  // Get video details
  async getVideoDetails(req, res) {
    try {
      const { videoId } = req.params;

      if (!YOUTUBE_API_KEY) {
        return res.status(500).json({ 
          error: { 
            message: 'YouTube API key not configured',
            status: 500 
          } 
        });
      }

      const response = await axios.get(`${YOUTUBE_API_BASE}/videos`, {
        params: {
          key: YOUTUBE_API_KEY,
          id: videoId,
          part: 'snippet,contentDetails,statistics'
        }
      });

      if (response.data.items.length === 0) {
        return res.status(404).json({ error: { message: 'Video not found', status: 404 } });
      }

      const video = response.data.items[0];
      const viewCount = parseInt(video.statistics.viewCount || '0');
      
      const details = {
        videoId: video.id,
        title: video.snippet.title,
        description: video.snippet.description,
        thumbnail: video.snippet.thumbnails.high?.url || video.snippet.thumbnails.medium.url,
        channelId: video.snippet.channelId,
        channelTitle: video.snippet.channelTitle,
        publishedAt: video.snippet.publishedAt,
        duration: video.contentDetails.duration,
        viewCount: viewCount,
        likeCount: parseInt(video.statistics.likeCount || '0'),
        suggestedPrice: calculatePriceFromViews(viewCount),
      };

      res.json({ video: details });
    } catch (error) {
      console.error('YouTube video details error:', error.response?.data || error.message);
      
      res.status(500).json({ 
        error: { 
          message: 'Error getting video details',
          status: 500 
        } 
      });
    }
  }
};

// Helper function to calculate price based on view count
function calculatePriceFromViews(views) {
  // Formula: Base price + (views / 100000) capped between $5 - $99.99
  const basePrice = 5.00;
  const pricePerHundredKViews = 1.50;
  
  const calculatedPrice = basePrice + (views / 100000) * pricePerHundredKViews;
  
  // Cap between $5 and $99.99
  const finalPrice = Math.min(Math.max(calculatedPrice, 5.00), 99.99);
  
  // Round to 2 decimals
  return Math.round(finalPrice * 100) / 100;
}

module.exports = youtubeController;


