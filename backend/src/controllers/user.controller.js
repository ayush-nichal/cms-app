const userService = require('../services/user.service');
const authService = require('../services/auth.service');
const emailService = require('../services/email.service');

class UserController {
  async getAll(req, res, next) {
    try {
      const users = await userService.getAll();
      users.forEach(u => delete u.password_hash);
      res.status(200).json(users);
    } catch (error) { next(error); }
  }

  async getById(req, res, next) {
    try {
      const user = await userService.getById(req.params.id);
      delete user.password_hash;
      res.status(200).json(user);
    } catch (error) { next(error); }
  }

  async create(req, res, next) {
    try {
      const { email, password, whatsapp_number } = req.body;
      if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
      }
      const user = await userService.create(email, password, whatsapp_number);
      delete user.password_hash;
      res.status(201).json(user);
    } catch (error) { next(error); }
  }

  async update(req, res, next) {
    try {
      const user = await userService.update(req.params.id, req.body);
      delete user.password_hash;
      res.status(200).json(user);
    } catch (error) { next(error); }
  }

  async delete(req, res, next) {
    try {
      await userService.softDelete(req.params.id);
      res.status(204).send();
    } catch (error) { next(error); }
  }

  async addAssignment(req, res, next) {
    try {
      const { channelId } = req.body;
      if (!channelId) {
        return res.status(400).json({ message: 'Channel ID is required' });
      }
      const assignment = await userService.addAssignment(req.params.id, channelId);
      res.status(201).json(assignment);
    } catch (error) { next(error); }
  }

  async removeAssignment(req, res, next) {
    try {
      await userService.removeAssignment(req.params.id, req.params.channelId);
      res.status(204).send();
    } catch (error) { next(error); }
  }

  async getAssignments(req, res, next) {
    try {
      const assignments = await userService.getAssignments(req.params.id);
      res.status(200).json(assignments);
    } catch (error) { next(error); }
  }

  async sendResetLink(req, res, next) {
    try {
      const { id } = req.params;
      const user = await userService.getById(id);
      
      const token = authService.generateResetToken(user.id);
      
      const resetUrl = `${req.protocol}://${req.get('host')}/reset-password?token=${token}`;
      
      const htmlBody = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #005DAC;">Password Reset Request</h2>
          <p>You are receiving this email because a password reset was requested for your account.</p>
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

      res.status(200).json({ message: 'Reset link sent to user email' });
    } catch (error) { next(error); }
  }
}

module.exports = new UserController();
