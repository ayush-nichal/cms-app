const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

class PlatformService {
  async getAll() {
    return prisma.platform.findMany({
      include: {
        _count: {
          select: { channels: true }
        }
      },
      orderBy: { created_at: 'desc' }
    });
  }

  async getById(id) {
    const platform = await prisma.platform.findUnique({
      where: { id },
      include: { channels: true }
    });
    if (!platform) throw { statusCode: 404, message: 'Platform not found' };
    return platform;
  }

  async create(name) {
    const existing = await prisma.platform.findUnique({ where: { name } });
    if (existing) throw { statusCode: 400, message: 'Platform name already exists' };

    return prisma.platform.create({
      data: { name }
    });
  }

  async update(id, name) {
    const existing = await prisma.platform.findUnique({ where: { id } });
    if (!existing) throw { statusCode: 404, message: 'Platform not found' };

    const duplicate = await prisma.platform.findFirst({
      where: { name, id: { not: id } }
    });
    if (duplicate) throw { statusCode: 400, message: 'Platform name already exists' };

    return prisma.platform.update({
      where: { id },
      data: { name }
    });
  }

  async delete(id) {
    const platform = await prisma.platform.findUnique({
      where: { id },
      include: { _count: { select: { channels: true } } }
    });
    
    if (!platform) throw { statusCode: 404, message: 'Platform not found' };
    if (platform._count.channels > 0) {
      throw { statusCode: 400, message: 'Cannot delete platform: channels exist under it' };
    }

    return prisma.platform.delete({ where: { id } });
  }
  async getSchedules(id) {
    const platform = await prisma.platform.findUnique({ where: { id } });
    if (!platform) throw { statusCode: 404, message: 'Platform not found' };

    return prisma.schedule.findMany({
      where: { channel: { platform_id: id } },
      orderBy: { scheduled_at: 'desc' },
      include: {
        channel: true,
        creator: {
          select: { email: true }
        },
        statusUpdatedBy: {
          select: { email: true }
        }
      }
    });
  }
}

module.exports = new PlatformService();
