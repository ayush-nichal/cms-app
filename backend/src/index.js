const app = require('./app');
const env = require('./config/env');

const { startNotificationJob } = require('./jobs/notification.job');

const PORT = env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
  startNotificationJob();
});
