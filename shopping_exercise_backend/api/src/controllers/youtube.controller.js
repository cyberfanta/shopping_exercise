const { validationResult } = require('express-validator');
const axios = require('axios');

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY || 'YOUR_YOUTUBE_API_KEY';
const YOUTUBE_API_BASE = 'https://www.googleapis.com/youtube/v3';

const youtubeController = {
  // Search YouTube videos
  async searchVideos(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { q, maxResults = 10 } = req.query;

      const response = await axios.get(`${YOUTUBE_API_BASE}/search`, {
        params: {
          key: YOUTUBE_API_KEY,
          q,
          part: 'snippet',
          type: 'video',
          maxResults,
          videoEmbeddable: true
        }
      });

      const videos = response.data.items.map(item => ({
        videoId: item.id.videoId,
        title: item.snippet.title,
        description: item.snippet.description,
        thumbnail: item.snippet.thumbnails.medium.url,
        channelTitle: item.snippet.channelTitle,
        publishedAt: item.snippet.publishedAt
      }));

      res.json({ videos });
    } catch (error) {
      console.error('YouTube search error:', error.response?.data || error.message);
      
      // Return mock data if API key is not configured
      if (error.response?.status === 400 || error.code === 'ENOTFOUND') {
        return res.json({
          videos: [
            {
              videoId: 'dQw4w9WgXcQ',
              title: 'Video de ejemplo 1',
              description: 'Configura YOUTUBE_API_KEY para búsquedas reales',
              thumbnail: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
              channelTitle: 'Canal de ejemplo',
              publishedAt: new Date().toISOString()
            }
          ],
          note: 'Usando datos de ejemplo. Configura YOUTUBE_API_KEY en .env'
        });
      }

      res.status(500).json({ error: { message: 'Error searching videos', status: 500 } });
    }
  },

  // Get video details
  async getVideoDetails(req, res) {
    try {
      const { videoId } = req.params;

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
      const details = {
        videoId: video.id,
        title: video.snippet.title,
        description: video.snippet.description,
        thumbnail: video.snippet.thumbnails.high.url,
        channelTitle: video.snippet.channelTitle,
        publishedAt: video.snippet.publishedAt,
        duration: video.contentDetails.duration,
        viewCount: video.statistics.viewCount,
        likeCount: video.statistics.likeCount
      };

      res.json({ video: details });
    } catch (error) {
      console.error('YouTube video details error:', error.response?.data || error.message);
      
      // Return mock data if API key is not configured
      if (error.response?.status === 400 || error.code === 'ENOTFOUND') {
        return res.json({
          video: {
            videoId: req.params.videoId,
            title: 'Video de ejemplo',
            description: 'Configura YOUTUBE_API_KEY para obtener detalles reales',
            thumbnail: `https://i.ytimg.com/vi/${req.params.videoId}/hqdefault.jpg`,
            channelTitle: 'Canal de ejemplo',
            publishedAt: new Date().toISOString(),
            duration: 'PT5M30S',
            viewCount: '1000',
            likeCount: '100'
          },
          note: 'Usando datos de ejemplo. Configura YOUTUBE_API_KEY en .env'
        });
      }

      res.status(500).json({ error: { message: 'Error getting video details', status: 500 } });
    }
  }
};

module.exports = youtubeController;

