const authService = require('../services/auth.service');

class AuthController {
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
}

module.exports = new AuthController();
