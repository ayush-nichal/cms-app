const authService = require('../services/auth.service');
const userService = require('../services/user.service');
const emailService = require('../services/email.service');

class AuthController {
  async forgotPassword(req, res, next) {
    try {
      const { email } = req.body;
      if (!email) {
        return res.status(400).json({ message: 'Email is required' });
      }

      const user = await userService.getByEmail(email);
      
      // If user exists, send reset link. If not, don't throw error (Security: prevent user enumeration)
      if (user) {
        const token = authService.generateResetToken(user.id);
        const resetUrl = `${req.protocol}://${req.get('host')}/reset-password?token=${token}`;
        
        const htmlBody = `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
            <h2 style="color: #005DAC;">Password Reset Request</h2>
            <p>You requested a password reset for your CMS App account.</p>
            <div style="text-align: center; margin: 30px 0;">
              <a href="${resetUrl}" style="background-color: #005DAC; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">Reset Password</a>
            </div>
            <p>If you did not request this, please ignore this email.</p>
            <p style="font-size: 12px; color: #888;">Note: This link will expire in 1 hour.</p>
          </div>
        `;

        await emailService.sendEmail(
          user.email,
          'Reset Your Password - CMS App',
          `Reset your password here: ${resetUrl}`,
          htmlBody
        );
      }

      // Always return success to protect user privacy
      res.status(200).json({ message: 'If an account exists for this email, a reset link has been sent.' });
    } catch (error) {
      next(error);
    }
  }
  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      
      if (!email || !password) {
        return res.status(400).json({ error: true, code: 400, message: 'Email and password are required' });
      }

      const token = await authService.login(email, password);
      
      const decoded = authService.verifyToken(token);
      const user = await authService.getUserById(decoded.userId);

      res.status(200).json({
        token,
        user
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(req, res, next) {
    try {
      res.status(200).json({ success: true });
    } catch (error) {
      next(error);
    }
  }

  async me(req, res, next) {
    try {
      const user = await authService.getUserById(req.user.userId);
      res.status(200).json(user);
    } catch (error) {
      next(error);
    }
  }

  async resetPassword(req, res, next) {
    try {
      const { token, password } = req.body;
      if (!token || !password) {
        return res.status(400).json({ message: 'Token and password are required' });
      }

      const decoded = authService.verifyResetToken(token);
      
      // We use a direct prisma update here to bypass the "not admin" check in userService.update 
      // if the token is validly generated for that user.
      // But for security, let's just use userService but ensure it's handled.
      // Actually, userService.update is fine for creators.
      await userService.update(decoded.userId, { password });

      res.status(200).json({ message: 'Password has been reset successfully' });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();
