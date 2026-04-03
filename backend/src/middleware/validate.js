const { z } = require('zod');

const validateBody = (schema) => {
  return (req, res, next) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (err) {
      if (err.errors) {
        return res.status(400).json({ error: err.errors.map(e => `${e.path.join('.')}: ${e.message}`).join(', ') });
      }
      next(err);
    }
  };
};

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

const createUserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  role: z.enum(['admin', 'user']),
  whatsapp_number: z.string().optional().nullable()
});

const createScheduleSchema = z.object({
  channelId: z.string().min(1),
  title: z.string().min(1).max(100),
  contentType: z.enum(['post', 'video']),
  description: z.string().max(500).optional().nullable(),
  scheduledAt: z.string().datetime()
});

const updateStatusSchema = z.object({
  status: z.enum(['scheduled', 'posted', 'not_posted'])
});

module.exports = {
  validateBody,
  loginSchema,
  createUserSchema,
  createScheduleSchema,
  updateStatusSchema
};
