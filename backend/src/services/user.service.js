const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

class UserService {
  async getAll() {
    return prisma.user.findMany({
      where: { role: { not: 'admin' } },
      include: {
        assignments: {
          include: {
            channel: {
              include: { platform: true }
            }
          }
        }
      },
      orderBy: { created_at: 'desc' }
    });
  }

  async getById(id) {
    const user = await prisma.user.findFirst({
      where: { id, role: { not: 'admin' } },
      include: {
        assignments: {
          include: {
            channel: {
              include: { platform: true }
            }
          }
        }
      }
    });
    if (!user) throw { statusCode: 404, message: 'User not found' };
    return user;
  }

  async create(email, password, role, whatsapp_number) {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw { statusCode: 400, message: 'Email already exists' };

    const password_hash = await bcrypt.hash(password, 12);

    return prisma.user.create({
      data: {
        email,
        password_hash,
        role,
        whatsapp_number: whatsapp_number || null,
        is_active: true
      }
    });
  }

  async update(id, data) {
    const user = await prisma.user.findFirst({ where: { id, role: { not: 'admin' } } });
    if (!user) throw { statusCode: 404, message: 'User not found' };

    const updateData = {};
    if (data.email) {
      const existing = await prisma.user.findFirst({ where: { email: data.email, id: { not: id } } });
      if (existing) throw { statusCode: 400, message: 'Email already exists' };
      updateData.email = data.email;
    }
    if (data.password) {
      updateData.password_hash = await bcrypt.hash(data.password, 12);
    }
    if (data.role) updateData.role = data.role;
    if (data.whatsapp_number !== undefined) updateData.whatsapp_number = data.whatsapp_number || null;
    if (data.callmebot_api_key !== undefined) updateData.callmebot_api_key = data.callmebot_api_key || null;

    return prisma.user.update({
      where: { id },
      data: updateData
    });
  }

  async softDelete(id) {
    const user = await prisma.user.findFirst({ where: { id, role: { not: 'admin' } } });
    if (!user) throw { statusCode: 404, message: 'User not found or cannot delete admin' };

    return prisma.user.update({
      where: { id },
      data: { is_active: false }
    });
  }

  async addAssignment(userId, channelId, role) {
    const existing = await prisma.userChannelAssignment.findFirst({
      where: { user_id: userId, channel_id: channelId }
    });
    if (existing) throw { statusCode: 400, message: 'Assignment already exists' };

    return prisma.userChannelAssignment.create({
      data: {
        user_id: userId,
        channel_id: channelId,
        role
      },
      include: {
        channel: {
          include: { platform: true }
        }
      }
    });
  }

  async removeAssignment(userId, channelId) {
    const assignment = await prisma.userChannelAssignment.findFirst({
      where: { user_id: userId, channel_id: channelId }
    });
    if (!assignment) throw { statusCode: 404, message: 'Assignment not found' };

    return prisma.userChannelAssignment.delete({
      where: { id: assignment.id }
    });
  }

  async getAssignments(userId) {
    return prisma.userChannelAssignment.findMany({
      where: { user_id: userId },
      include: {
        channel: {
          include: { platform: true }
        }
      }
    });
  }
}

module.exports = new UserService();
