const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

async function sendEmail(to, subject, textBody, htmlBody) {
  try {
    await transporter.sendMail({
      from: `"CMS App" <${process.env.GMAIL_USER}>`,
      to,
      subject,
      text: textBody,
      html: htmlBody
    });
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

module.exports = { sendEmail };
