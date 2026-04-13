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
const versionRoutes = require('./routes/version.routes');
const rateLimit = require('express-rate-limit');

const app = express();

// Trust Render's reverse proxy so req.protocol returns 'https' correctly
// Required for password reset URLs in emails to use https://
app.set('trust proxy', 1);

// 1. Apply CORS first to allow all incoming requests
app.use(cors());

// 2. The Bridge Route (Bypass heavy middleware)
app.get('/reset-password', (req, res) => {
  console.log('--- DEBUG: Reset Password Bridge Request ---');
  console.log('User-Agent:', req.headers['user-agent']);
  res.sendFile(require('path').join(__dirname, '..', 'public', 'reset-password.html'));
});

// 3. Global Security & Rate Limiting (After the bridge)
app.use(helmet({
  contentSecurityPolicy: false, // Relax CSP for local testing
}));
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
app.use(express.static('public'));
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
app.use('/api/version', versionRoutes);

app.use(errorHandler);

module.exports = app;
