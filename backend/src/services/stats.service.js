const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class StatsService {
  async getOverview(from, to) {
    const whereClause = {};
    if (from || to) {
      whereClause.scheduled_at = {};
      if (from) whereClause.scheduled_at.gte = new Date(from);
      if (to) whereClause.scheduled_at.lte = new Date(to);
    }

    const platforms = await prisma.platform.findMany({
      include: {
        channels: {
          include: {
            schedules: {
              where: whereClause
            }
          }
        }
      }
    });

    const results = platforms.map(p => {
      let total = 0;
      for (const channel of p.channels) {
        total += channel.schedules.length;
      }
      return {
        platformId: p.id,
        platformName: p.name,
        total,
      };
    });

    return results;
  }

  async getPlatformStats(platformId, from, to) {
    const whereClause = {};
    if (from || to) {
      whereClause.scheduled_at = {};
      if (from) whereClause.scheduled_at.gte = new Date(from);
      if (to) whereClause.scheduled_at.lte = new Date(to);
    }

    const channels = await prisma.channel.findMany({
      where: { platform_id: platformId },
      include: {
        schedules: {
          where: whereClause
        }
      }
    });

    return channels.map(c => ({
      channelId: c.id,
      channelName: c.name,
      handle: c.handle,
      total: c.schedules.length,
    }));
  }
}

module.exports = new StatsService();
