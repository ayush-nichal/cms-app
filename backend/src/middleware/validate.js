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
  whatsapp_number: z.string().optional().nullable()
});

const createScheduleSchema = z.object({
  channelId: z.string().min(1),
  title: z.string().min(1).max(100),
  contentType: z.enum(['text_post', 'image_post', 'short_form_video', 'long_form_video', 'carousel_post']),
  description: z.string().max(500).optional().nullable(),
  scheduledAt: z.string().datetime()
});

module.exports = {
  validateBody,
  loginSchema,
  createUserSchema,
  createScheduleSchema
};
