const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class ScheduleService {
  async _checkAssignment(userId, channelId) {
    const assignment = await prisma.userChannelAssignment.findFirst({
      where: { user_id: userId, channel_id: channelId }
    });
    if (!assignment) {
      throw { statusCode: 403, message: 'Forbidden: You are not assigned to this channel' };
    }
    return assignment;
  }

  async getByChannel(channelId, userId, page = 1, limit = 20) {
    if (!channelId) throw { statusCode: 400, message: 'channelId query parameter is required' };
    await this._checkAssignment(userId, channelId);
    const skip = (page - 1) * limit;

    const [total, items] = await Promise.all([
      prisma.schedule.count({ where: { channel_id: channelId } }),
      prisma.schedule.findMany({
        where: { channel_id: channelId },
        skip,
        take: parseInt(limit, 10),
        orderBy: { scheduled_at: 'desc' },
        include: {
          creator: { select: { email: true } },
          statusUpdatedBy: { select: { email: true } }
        }
      })
    ]);

    return { total, page: parseInt(page, 10), items };
  }

  async getById(id, userId) {
    const schedule = await prisma.schedule.findUnique({
      where: { id },
      include: {
        creator: { select: { email: true } },
        statusUpdatedBy: { select: { email: true } }
      }
    });
    if (!schedule) throw { statusCode: 404, message: 'Schedule not found' };
    await this._checkAssignment(userId, schedule.channel_id);
    return schedule;
  }

  async create(data, userId) {
    const assignment = await this._checkAssignment(userId, data.channelId);
    if (assignment.role !== 'creator') {
      throw { statusCode: 403, message: 'Forbidden: Only creators can create schedules' };
    }

    return prisma.schedule.create({
      data: {
        channel_id: data.channelId,
        created_by: userId,
        title: data.title,
        content_type: data.contentType,
        description: data.description || null,
        media_url: data.mediaUrl || null,
        scheduled_at: new Date(data.scheduledAt),
      },
      include: {
        creator: { select: { email: true } },
        statusUpdatedBy: { select: { email: true } }
      }
    });
  }

  async update(id, data, userId) {
    const schedule = await prisma.schedule.findUnique({ where: { id } });
    if (!schedule) throw { statusCode: 404, message: 'Schedule not found' };
    
    const assignment = await this._checkAssignment(userId, schedule.channel_id);
    if (assignment.role !== 'creator') {
      throw { statusCode: 403, message: 'Forbidden: Only creators can edit schedules' };
    }

    return prisma.schedule.update({
      where: { id },
      data: {
        title: data.title,
        content_type: data.contentType,
        description: data.description || null,
        media_url: data.mediaUrl !== undefined ? data.mediaUrl : undefined,
        scheduled_at: data.scheduledAt ? new Date(data.scheduledAt) : undefined,
      },
      include: {
        creator: { select: { email: true } },
        statusUpdatedBy: { select: { email: true } }
      }
    });
  }

  async delete(id, userId) {
    const schedule = await prisma.schedule.findUnique({ where: { id } });
    if (!schedule) throw { statusCode: 404, message: 'Schedule not found' };

    const assignment = await this._checkAssignment(userId, schedule.channel_id);
    if (assignment.role !== 'creator') {
      throw { statusCode: 403, message: 'Forbidden: Only creators can delete schedules' };
    }

    if (schedule.media_url) {
      const mediaService = require('./media.service');
      mediaService.deleteFile(schedule.media_url).catch(e => {
        console.error('Background media deletion failed:', e);
      });
    }

    await prisma.schedule.delete({ where: { id } });
  }

  async updateStatus(id, newStatus, userId) {
    const validStatuses = ['scheduled', 'posted', 'not_posted'];
    if (!validStatuses.includes(newStatus)) {
      throw { statusCode: 400, message: 'Invalid status value' };
    }

    const schedule = await prisma.schedule.findUnique({ where: { id } });
    if (!schedule) throw { statusCode: 404, message: 'Schedule not found' };

    await this._checkAssignment(userId, schedule.channel_id);

    return prisma.schedule.update({
      where: { id },
      data: {
        status: newStatus,
        status_updated_by: userId,
        status_updated_at: new Date(),
      },
      include: {
        creator: { select: { email: true } },
        statusUpdatedBy: { select: { email: true } }
      }
    });
  }
}

module.exports = new ScheduleService();
