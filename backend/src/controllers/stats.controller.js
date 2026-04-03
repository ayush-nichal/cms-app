const statsService = require('../services/stats.service');

class StatsController {
  async getOverview(req, res, next) {
    try {
      const { from, to } = req.query;
      const stats = await statsService.getOverview(from, to);
      res.status(200).json(stats);
    } catch (e) { next(e); }
  }

  async getPlatformStats(req, res, next) {
    try {
      const { from, to } = req.query;
      const stats = await statsService.getPlatformStats(req.params.id, from, to);
      res.status(200).json(stats);
    } catch (e) { next(e); }
  }
}

module.exports = new StatsController();
