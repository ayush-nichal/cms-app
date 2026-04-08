const analyticsService = require('../services/analytics.service');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class AnalyticsController {
  
  async getDashboardSummary(req, res) {
    const { from, to } = req.query;
    const fromDate = from ? new Date(from) : new Date(0);
    const toDate = to ? new Date(to) : new Date('2100-01-01');

    const total = await prisma.schedule.count({
      where: { scheduled_at: { gte: fromDate, lte: toDate } }
    });
    
    const recent = await prisma.schedule.findMany({
      take: 10,
      orderBy: { created_at: 'desc' },
      include: {
        channel: {
          include: { platform: true }
        },
        creator: { select: { email: true } }
      }
    });

    res.json({ total, recent });
  }

  // Platform Level Methods
  async getPipelineForecast(req, res) {
    const { id } = req.params;
    const { from, to } = req.query;
    if (!id) return res.status(400).json({ message: 'Platform ID is required' });
    const data = await analyticsService.getPipelineForecast(id, from, to);
    res.json(data);
  }

  async getWorkloadDistribution(req, res) {
    const { id } = req.params;
    const { from, to } = req.query;
    if (!id) return res.status(400).json({ message: 'Platform ID is required' });
    const data = await analyticsService.getWorkloadDistribution(id, from, to);
    res.json(data);
  }

  async getPlatformContentMix(req, res) {
    const { id } = req.params;
    const { from, to } = req.query;
    if (!id) return res.status(400).json({ message: 'Platform ID is required' });
    const data = await analyticsService.getPlatformContentMix(id, from, to);
    res.json(data);
  }

  // Moved from platform route for admin aggregate view
  async getRecentSchedulesTotal(req, res) {
    const { id } = req.params;
    if (!id) return res.status(400).json({ message: 'Platform ID is required' });
    
    // Temporary logic to return total schedules or recent ones. User specified "move existing endpoint here".
    // We assume the user wants recent schedules under this platform
    const channels = await prisma.channel.findMany({ where: { platform_id: id }});
    if (!channels.length) return res.json([]);
    const recent = await prisma.schedule.findMany({
      where: { channel_id: { in: channels.map(c => c.id) } },
      take: 10,
      orderBy: { created_at: 'desc' },
      include: {
        channel: {
          include: { platform: true }
        },
        creator: { select: { email: true } }
      }
    });
    res.json(recent);
  }


  // Channel Level Methods
  async getCoverageHeatmap(req, res) {
    const { id } = req.params;
    const { month, year } = req.query;
    if (!id) return res.status(400).json({ message: 'Channel ID is required' });
    const data = await analyticsService.getCoverageHeatmap(id, month, year);
    res.json(data);
  }

  async getLeadTime(req, res) {
    const { id } = req.params;
    const { from, to } = req.query;
    if (!id) return res.status(400).json({ message: 'Channel ID is required' });
    const data = await analyticsService.getLeadTime(id, from, to);
    res.json(data);
  }

  async getChannelContentMix(req, res) {
    const { id } = req.params;
    const { from, to } = req.query;
    if (!id) return res.status(400).json({ message: 'Channel ID is required' });
    const data = await analyticsService.getChannelContentMix(id, from, to);
    res.json(data);
  }

  async getChannelTrend(req, res) {
    const { id } = req.params;
    const { days } = req.query;
    if (!id) return res.status(400).json({ message: 'Channel ID is required' });
    const data = await analyticsService.getChannelTrend(id, days);
    res.json(data);
  }
}

module.exports = new AnalyticsController();
