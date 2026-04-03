const userService = require('../services/user.service');

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
      const { email, password, role, whatsapp_number } = req.body;
      if (!email || !password || !role) {
        return res.status(400).json({ message: 'Email, password, and role are required' });
      }
      const user = await userService.create(email, password, role, whatsapp_number);
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
      const { channelId, role } = req.body;
      if (!channelId || !role) {
        return res.status(400).json({ message: 'Channel ID and role are required' });
      }
      const assignment = await userService.addAssignment(req.params.id, channelId, role);
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
}

module.exports = new UserController();
