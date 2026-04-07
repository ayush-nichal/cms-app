const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class ChannelService {
  async getByPlatform(platform_id) {
    return prisma.channel.findMany({
      where: { platform_id },
      include: {
        schedules: {
          where: { scheduled_at: { lte: new Date() } },
          orderBy: { scheduled_at: 'desc' },
          take: 1,
          select: { scheduled_at: true }
        }
      },
      orderBy: { created_at: 'desc' }
    });
  }

  async getById(id) {
    const channel = await prisma.channel.findUnique({
      where: { id },
      include: { platform: true }
    });
    if (!channel) throw { statusCode: 404, message: 'Channel not found' };
    return channel;
  }

  async create(platform_id, name, handle) {
    const platform = await prisma.platform.findUnique({ where: { id: platform_id } });
    if (!platform) throw { statusCode: 404, message: 'Platform not found' };

    return prisma.channel.create({
      data: { platform_id, name, handle }
    });
  }

  async update(id, name, handle) {
    const existing = await prisma.channel.findUnique({ where: { id } });
    if (!existing) throw { statusCode: 404, message: 'Channel not found' };

    return prisma.channel.update({
      where: { id },
      data: { name, handle }
    });
  }

  async delete(id) {
    const channel = await prisma.channel.findUnique({
      where: { id },
      include: { _count: { select: { assignments: true, schedules: true } } }
    });

    if (!channel) throw { statusCode: 404, message: 'Channel not found' };
    
    if (channel._count.assignments > 0) {
      throw { statusCode: 400, message: 'Cannot delete channel: users are assigned to it' };
    }
    if (channel._count.schedules > 0) {
      throw { statusCode: 400, message: 'Cannot delete channel: schedules exist for it' };
    }

    return prisma.channel.delete({ where: { id } });
  }
}

module.exports = new ChannelService();
