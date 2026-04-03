const mediaService = require('../services/media.service');

class MediaController {
  async upload(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
      }

      const mimeType = req.file.mimetype;
      const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime'];
      
      if (!allowedMimeTypes.includes(mimeType)) {
        return res.status(400).json({ error: 'Invalid file type' });
      }

      const publicUrl = await mediaService.uploadFile(
        req.file.buffer, 
        req.file.originalname, 
        mimeType, 
        req.user.userId
      );

      res.status(200).json({ url: publicUrl });
    } catch (e) {
      next(e);
    }
  }

  async delete(req, res, next) {
    try {
      const { mediaUrl } = req.body;
      if (!mediaUrl) {
        return res.status(400).json({ error: 'mediaUrl is required' });
      }
      
      const success = await mediaService.deleteFile(mediaUrl);
      res.status(200).json({ success });
    } catch (e) {
      next(e);
    }
  }
}

module.exports = new MediaController();
