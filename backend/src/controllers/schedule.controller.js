const scheduleService = require('../services/schedule.service');

class ScheduleController {
  async getAllByChannel(req, res, next) {
    try {
      const { channelId, page, limit } = req.query;
      const result = await scheduleService.getByChannel(channelId, req.user.userId, page, limit);
      res.status(200).json(result);
    } catch (error) { next(error); }
  }

  async getById(req, res, next) {
    try {
      const schedule = await scheduleService.getById(req.params.id, req.user.userId);
      res.status(200).json(schedule);
    } catch (error) { next(error); }
  }

  async create(req, res, next) {
    try {
      const { channelId, title, contentType, scheduledAt } = req.body;
      if (!channelId || !title || !contentType || !scheduledAt) {
        return res.status(400).json({ message: 'channelId, title, contentType, and scheduledAt are required' });
      }
      const schedule = await scheduleService.create(req.body, req.user.userId);
      res.status(201).json(schedule);
    } catch (error) { next(error); }
  }

  async update(req, res, next) {
    try {
      const schedule = await scheduleService.update(req.params.id, req.body, req.user.userId);
      res.status(200).json(schedule);
    } catch (error) { next(error); }
  }

  async delete(req, res, next) {
    try {
      await scheduleService.delete(req.params.id, req.user.userId);
      res.status(204).send();
    } catch (error) { next(error); }
  }

  async updateStatus(req, res, next) {
    try {
      const { status } = req.body;
      if (!status) {
        return res.status(400).json({ message: 'status field is required' });
      }
      const schedule = await scheduleService.updateStatus(req.params.id, status, req.user.userId);
      res.status(200).json(schedule);
    } catch (error) { next(error); }
  }
}

module.exports = new ScheduleController();
