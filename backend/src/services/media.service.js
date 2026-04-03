const { createClient } = require('@supabase/supabase-js');
const env = require('../config/env');

const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_KEY);

class MediaService {
  async uploadFile(fileBuffer, fileName, mimeType, userId) {
    const timestamp = Date.now();
    const randomId = Math.random().toString(36).substring(2, 8);
    const ext = fileName.split('.').pop() || '';
    const filePath = `schedules/${userId}/${timestamp}-${randomId}.${ext}`;

    const { data, error } = await supabase.storage
      .from('schedule-media')
      .upload(filePath, fileBuffer, {
        contentType: mimeType,
      });

    if (error) {
      throw { statusCode: 500, message: `Supabase upload failed: ${error.message}` };
    }

    const { data: publicData } = supabase.storage
      .from('schedule-media')
      .getPublicUrl(filePath);

    return publicData.publicUrl;
  }

  async deleteFile(mediaUrl) {
    try {
      const bucketName = 'schedule-media';
      const bucketMarker = `${bucketName}/`;
      const idx = mediaUrl.indexOf(bucketMarker);
      if (idx === -1) return false;

      const filePath = mediaUrl.substring(idx + bucketMarker.length);
      if (!filePath) return false;

      const { data, error } = await supabase.storage
        .from(bucketName)
        .remove([filePath]);
        
      if (error) {
        console.error('Supabase remove error:', error);
        return false;
      }
      return true;
    } catch (e) {
      console.error('Failed to delete media:', e);
      return false;
    }
  }
}

module.exports = new MediaService();
