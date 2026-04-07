// IMPORTANT: Render free tier sleeps after 15 min inactivity.
// Set up UptimeRobot (free) to ping GET /health every 5 minutes.
// Without this, the 9:00 AM cron job may not fire if the server is asleep.
// Setup: https://uptimerobot.com → New Monitor → HTTP(s) → your /health URL → every 5 min

const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');
const callMeBotService = require('../services/callmebot.service');
const emailService = require('../services/email.service');

const prisma = new PrismaClient();

async function runNotificationJob() {
  console.log('Starting consolidated notification job...');
  let sentEmails = 0;
  let sentWhatsApp = 0;
  let failedEmails = 0;
  let failedWhatsApp = 0;

  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Fetch ALL schedules that are technically pending
    const upcomingSchedules = await prisma.schedule.findMany({
      include: {
        channel: {
          include: {
            platform: true,
            assignments: {
              include: { user: true }
            }
          }
        }
      }
    });

    // 2. Filter schedules exactly between 0 and 3 days out, and Group them cleanly per User
    const userMap = new Map();

    for (const schedule of upcomingSchedules) {
      const scheduleDate = new Date(schedule.scheduled_at);
      scheduleDate.setHours(0, 0, 0, 0);
      const diffTime = scheduleDate - today;
      const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays < 0 || diffDays > 3) continue;

      let daysString = diffDays === 0 ? 'today' : (diffDays === 1 ? 'tomorrow' : `in ${diffDays} days`);

      const assignments = schedule.channel.assignments;
      for (const assignment of assignments) {
        const user = assignment.user;
        
        if (!user.is_active) continue;

        if (!userMap.has(user.id)) {
          userMap.set(user.id, { user, items: [] });
        }
        
        userMap.get(user.id).items.push({
          schedule,
          diffDays,
          daysString
        });
      }
    }

    // 3. Dispatch digest to each User mapping 
    for (const [userId, data] of userMap.entries()) {
      const { user, items } = data;
      
      const validEmailItems = [];
      const validWaItems = [];

      for (const item of items) {
        const existingEmailLog = await prisma.notificationLog.findFirst({
          where: { user_id: user.id, schedule_id: item.schedule.id, channel: 'email', status: 'sent', sent_at: { gte: today } }
        });
        if (!existingEmailLog) validEmailItems.push(item);

        const existingWaLog = await prisma.notificationLog.findFirst({
          where: { user_id: user.id, schedule_id: item.schedule.id, channel: 'whatsapp', status: 'sent', sent_at: { gte: today } }
        });
        if (!existingWaLog && user.whatsapp_number && user.callmebot_api_key) {
          validWaItems.push(item);
        }
      }

      // SEND CONSOLIDATED EMAIL DIGEST
      if (validEmailItems.length > 0) {
        validEmailItems.sort((a,b) => a.diffDays - b.diffDays);
        const subject = `Upcoming: ${validEmailItems.length} Scheduled Post${validEmailItems.length > 1 ? 's' : ''}`;
        
        let tableRows = '';
        let plainTextList = '';
        for (const item of validEmailItems) {
          const formattedDate = new Date(item.schedule.scheduled_at).toLocaleDateString();
          tableRows += `
            <tr>
              <td style="padding: 10px; border-bottom: 1px solid #eee;"><strong>${item.schedule.channel.name}</strong><br><span style="color: #666; font-size: 12px;">${item.schedule.channel.platform.name}</span></td>
              <td style="padding: 10px; border-bottom: 1px solid #eee;">${formattedDate}</td>
              <td style="padding: 10px; border-bottom: 1px solid #eee; color: #d97706;"><strong>${item.daysString}</strong></td>
            </tr>
          `;
          plainTextList += `- ${item.schedule.channel.name} on ${item.schedule.channel.platform.name} due ${item.daysString} (${formattedDate})\n`;
        }

        const htmlBody = `
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden;">
          <div style="background-color: #1e293b; padding: 20px; text-align: center;">
             <h2 style="color: white; margin: 0;">Content Schedule Digest</h2>
          </div>
          <div style="padding: 24px;">
            <p style="font-size: 16px; color: #334155;">Hello,</p>
            <p style="font-size: 16px; color: #334155;">This is a consolidated reminder for your upcoming scheduled content:</p>
            
            <table style="width: 100%; border-collapse: collapse; margin: 24px 0; text-align: left; background: white;">
              <thead>
                <tr style="background-color: #f8fafc;">
                  <th style="padding: 12px 10px; border-bottom: 2px solid #e2e8f0; color: #475569; font-size: 14px; text-transform: uppercase;">Channel</th>
                  <th style="padding: 12px 10px; border-bottom: 2px solid #e2e8f0; color: #475569; font-size: 14px; text-transform: uppercase;">Date</th>
                  <th style="padding: 12px 10px; border-bottom: 2px solid #e2e8f0; color: #475569; font-size: 14px; text-transform: uppercase;">Due</th>
                </tr>
              </thead>
              <tbody>
                ${tableRows}
              </tbody>
            </table>
            
            <p style="font-size: 15px; color: #334155;">Please make sure all materials are finalized and ready.</p>
          </div>
          <div style="background-color: #f8fafc; padding: 16px; text-align: center; border-top: 1px solid #e2e8f0;">
             <p style="color: #94a3b8; font-size: 12px; margin: 0;">— Content Management Native App</p>
          </div>
        </div>`;

        const plainTextBody = `Hi,\n\nThis is a consolidated reminder for your upcoming scheduled content:\n\n${plainTextList}\nPlease make sure it is ready to go!`;

        const emailResult = await emailService.sendEmail(user.email, subject, plainTextBody, htmlBody);
        
        for (const item of validEmailItems) {
          await prisma.notificationLog.create({
            data: { user_id: user.id, channel_id: item.schedule.channel_id, schedule_id: item.schedule.id, channel: 'email', sent_at: new Date(), status: emailResult.success ? 'sent' : 'failed' }
          });
        }

        if (emailResult.success) {
          sentEmails++;
        } else { 
          failedEmails++; 
          console.error(`Email failed for user ${user.id}: ${emailResult.error}`); 
        }
      }

      // SEND CONSOLIDATED WHATSAPP DIGEST
      if (validWaItems.length > 0) {
        validWaItems.sort((a,b) => a.diffDays - b.diffDays);
        let plainTextList = '';
        for (const item of validWaItems) {
          plainTextList += `- ${item.schedule.channel.name} (${item.schedule.channel.platform.name}) due ${item.daysString}\n`;
        }
        
        const baseMessage = `Reminder! You have ${validWaItems.length} upcoming post(s):\n${plainTextList}Please ensure they are ready.`;
        
        const waResult = await callMeBotService.sendWhatsApp(user.whatsapp_number, user.callmebot_api_key, baseMessage);
        
        for (const item of validWaItems) {
          await prisma.notificationLog.create({
            data: { user_id: user.id, channel_id: item.schedule.channel_id, schedule_id: item.schedule.id, channel: 'whatsapp', sent_at: new Date(), status: waResult.success ? 'sent' : 'failed' }
          });
        }

        if (waResult.success) {
          sentWhatsApp++; 
        } else { 
          failedWhatsApp++; 
          console.error(`CallMeBot failed for user ${user.id}: ${waResult.error}`); 
        }
      }
    }
  } catch (error) {
    console.error('Critical error in notification job:', error);
  }

  console.log(`Notification job complete: ${sentEmails} digest emails sent, ${sentWhatsApp} WhatsApp texts sent, ${failedEmails} email failures, ${failedWhatsApp} WhatsApp failures.`);
}

function startNotificationJob() {
  console.log('Scheduling daily notification job for 09:00 AM');
  cron.schedule('0 9 * * *', runNotificationJob);
}

module.exports = { startNotificationJob, runNotificationJob };
