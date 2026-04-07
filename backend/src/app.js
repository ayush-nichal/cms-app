const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const errorHandler = require('./middleware/errorHandler');
const healthRoutes = require('./routes/health.routes');
const authRoutes = require('./routes/auth.routes');
const platformRoutes = require('./routes/platform.routes');
const channelRoutes = require('./routes/channel.routes');
const userRoutes = require('./routes/user.routes');
const scheduleRoutes = require('./routes/schedule.routes');
const statsRoutes = require('./routes/stats.routes');
const analyticsRoutes = require('./routes/analytics.routes');
const mediaRoutes = require('./routes/media.routes');
const rateLimit = require('express-rate-limit');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

const generalLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 200,
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
});

app.use(generalLimiter);
app.use('/auth/login', authLimiter);

app.use('/health', healthRoutes);
app.use('/auth', authRoutes);
app.use('/platforms', platformRoutes);
app.use('/channels', channelRoutes);
app.use('/users', userRoutes);
app.use('/schedules', scheduleRoutes);
app.use('/stats', statsRoutes);
app.use('/analytics', analyticsRoutes);
app.use('/media', mediaRoutes);

app.use(errorHandler);

module.exports = app;
