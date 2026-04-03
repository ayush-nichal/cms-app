const platformService = require('../services/platform.service');

class PlatformController {
  async getAll(req, res, next) {
    try {
      const platforms = await platformService.getAll();
      res.status(200).json(platforms);
    } catch (error) { next(error); }
  }

  async getById(req, res, next) {
    try {
      const platform = await platformService.getById(req.params.id);
      res.status(200).json(platform);
    } catch (error) { next(error); }
  }

  async create(req, res, next) {
    try {
      const { name } = req.body;
      if (!name) return res.status(400).json({ message: 'Name is required' });
      const platform = await platformService.create(name);
      res.status(201).json(platform);
    } catch (error) { next(error); }
  }

  async update(req, res, next) {
    try {
      const { name } = req.body;
      if (!name) return res.status(400).json({ message: 'Name is required' });
      const platform = await platformService.update(req.params.id, name);
      res.status(200).json(platform);
    } catch (error) { next(error); }
  }

  async delete(req, res, next) {
    try {
      await platformService.delete(req.params.id);
      res.status(204).send();
    } catch (error) { next(error); }
  }

  async getSchedules(req, res, next) {
    try {
      const schedules = await platformService.getSchedules(req.params.id);
      res.status(200).json(schedules);
    } catch (error) { next(error); }
  }
}

module.exports = new PlatformController();
