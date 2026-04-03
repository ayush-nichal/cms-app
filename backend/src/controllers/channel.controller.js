const channelService = require('../services/channel.service');

class ChannelController {
  async getById(req, res, next) {
    try {
      const channel = await channelService.getById(req.params.id);
      res.status(200).json(channel);
    } catch (error) { next(error); }
  }

  async create(req, res, next) {
    try {
      const { platform_id, name, handle } = req.body;
      if (!platform_id || !name || !handle) {
        return res.status(400).json({ message: 'Platform ID, name, and handle are required' });
      }
      const channel = await channelService.create(platform_id, name, handle);
      res.status(201).json(channel);
    } catch (error) { next(error); }
  }

  async update(req, res, next) {
    try {
      const { name, handle } = req.body;
      if (!name || !handle) {
        return res.status(400).json({ message: 'Name and handle are required' });
      }
      const channel = await channelService.update(req.params.id, name, handle);
      res.status(200).json(channel);
    } catch (error) { next(error); }
  }

  async delete(req, res, next) {
    try {
      await channelService.delete(req.params.id);
      res.status(204).send();
    } catch (error) { next(error); }
  }
}

module.exports = new ChannelController();
