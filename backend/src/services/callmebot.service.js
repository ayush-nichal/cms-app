const axios = require('axios');

class CallMeBotService {
  async sendWhatsApp(whatsappNumber, apiKey, message) {
    try {
      const encodedMessage = encodeURIComponent(message);
      const cleanPhone = whatsappNumber.startsWith('+') ? whatsappNumber.substring(1) : whatsappNumber;
      
      const url = `https://api.callmebot.com/whatsapp.php?phone=${cleanPhone}&text=${encodedMessage}&apikey=${apiKey}`;
      const response = await axios.get(url);
      
      if (response.data && response.data.includes('Message queued')) {
        return { success: true };
      } else {
        return { success: false, error: response.data || 'Unknown error' };
      }
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
}

module.exports = new CallMeBotService();
