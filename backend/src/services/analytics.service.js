const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

function getStartOfWeek(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  const day = d.getDay();
  // Match Monday-based week for business dashboards
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  return new Date(d.setDate(diff));
}

function getEndOfWeek(startOfWeek) {
  const d = new Date(startOfWeek);
  d.setDate(d.getDate() + 6);
  d.setHours(23, 59, 59, 999);
  return d;
}

function formatDateRange(start, end) {
  const sMonth = start.toLocaleString('en-US', { month: 'short' });
  const eMonth = end.toLocaleString('en-US', { month: 'short' });
  if (sMonth === eMonth) {
    return `${sMonth} ${start.getDate()}–${end.getDate()}`;
  }
  return `${sMonth} ${start.getDate()}–${eMonth} ${end.getDate()}`;
}

class AnalyticsService {
  async getPipelineForecast(platformId, fromDate, toDate) {
    const today = fromDate ? new Date(fromDate) : new Date();
    today.setHours(0, 0, 0, 0);
    const startOfCurrentWeek = getStartOfWeek(today);

    // Default to a 4-week lookahead
    const end = toDate ? new Date(toDate) : new Date(startOfCurrentWeek);
    if (!toDate) end.setDate(end.getDate() + 27); // 4 weeks total
    end.setHours(23, 59, 59, 999);

    const channels = await prisma.channel.findMany({ where: { platform_id: platformId } });
    if (!channels.length) return [];

    const schedules = await prisma.schedule.findMany({
      where: {
        channel_id: { in: channels.map(c => c.id) },
        scheduled_at: { gte: startOfCurrentWeek, lte: end }
      }
    });

    const weeks = {};
    for (let i = 0; i < 4; i++) {
       const weekStart = new Date(startOfCurrentWeek);
       weekStart.setDate(weekStart.getDate() + (i * 7));
       const weekEnd = getEndOfWeek(weekStart);
       const key = `week-${i}`;
       weeks[key] = {
         week: `Week ${i + 1}`,
         label: formatDateRange(weekStart, weekEnd),
         start: weekStart,
         end: weekEnd,
         count: 0
       };
    }

    for (const schedule of schedules) {
      const sDate = new Date(schedule.scheduled_at);
      for (const [key, w] of Object.entries(weeks)) {
        if (sDate >= w.start && sDate <= w.end) {
          w.count++;
          break;
        }
      }
    }

    return Object.values(weeks).map(w => ({ week: w.week, label: w.label, count: w.count }));
  }

  async getWorkloadDistribution(platformId, fromDate, toDate) {
    const from = fromDate ? new Date(fromDate) : new Date(0);
    const to = toDate ? new Date(toDate) : new Date('2100-01-01');

    const channels = await prisma.channel.findMany({ where: { platform_id: platformId } });
    if (!channels.length) return [];

    const schedules = await prisma.schedule.groupBy({
      by: ['channel_id'],
      where: {
        channel_id: { in: channels.map(c => c.id) },
        scheduled_at: { gte: from, lte: to }
      },
      _count: { _all: true }
    });

    const counts = channels.map(c => {
      const match = schedules.find(s => s.channel_id === c.id);
      return {
        channelId: c.id,
        handle: c.handle,
        name: c.name,
        count: match ? match._count._all : 0
      };
    });

    return counts.sort((a, b) => b.count - a.count);
  }

  async getPlatformContentMix(platformId, fromDate, toDate) {
    const from = fromDate ? new Date(fromDate) : new Date(0);
    const to = toDate ? new Date(toDate) : new Date('2100-01-01');

    const channels = await prisma.channel.findMany({ where: { platform_id: platformId } });
    if (!channels.length) return [];

    const counts = await prisma.schedule.groupBy({
      by: ['content_type'],
      where: {
        channel_id: { in: channels.map(c => c.id) },
        scheduled_at: { gte: from, lte: to }
      },
      _count: { _all: true }
    });

    const total = counts.reduce((acc, curr) => acc + curr._count._all, 0);
    if (total === 0) return [];

    return counts.map(c => ({
      contentType: c.content_type,
      count: c._count._all,
      percent: Math.round((c._count._all / total) * 1000) / 10
    })).sort((a, b) => b.count - a.count);
  }

  async getCoverageHeatmap(channelId, month, year) {
    const today = new Date();
    const m = month ? parseInt(month, 10) - 1 : today.getMonth();
    const y = year ? parseInt(year, 10) : today.getFullYear();

    const startOfMonth = new Date(y, m, 1);
    const endOfMonth = new Date(y, m + 1, 0); // Last day of month
    endOfMonth.setHours(23, 59, 59, 999);

    const schedules = await prisma.schedule.findMany({
      where: {
        channel_id: channelId,
        scheduled_at: { gte: startOfMonth, lte: endOfMonth }
      },
      select: { scheduled_at: true }
    });

    const map = {};
    const daysInMonth = endOfMonth.getDate();
    
    // Pre-fill days for exactly this month
    for (let i = 1; i <= daysInMonth; i++) {
        const yearStr = y;
        const monthStr = String(m + 1).padStart(2, '0');
        const dayStr = String(i).padStart(2, '0');
        map[`${yearStr}-${monthStr}-${dayStr}`] = 0;
    }

    for (const schedule of schedules) {
        // Convert the timestamp to YYYY-MM-DD
        const sDate = new Date(schedule.scheduled_at);
        // Using UTC dates to avoid local timezone skipping
        const yearStr = sDate.getUTCFullYear();
        const monthStr = String(sDate.getUTCMonth() + 1).padStart(2, '0');
        const dayStr = String(sDate.getUTCDate()).padStart(2, '0');
        
        const dateKey = `${yearStr}-${monthStr}-${dayStr}`;
        if (map[dateKey] !== undefined) {
             map[dateKey]++;
        }
    }

    return map;
  }

  async getLeadTime(channelId, fromDate, toDate) {
    const from = fromDate ? new Date(fromDate) : (() => { const d = new Date(); d.setMonth(d.getMonth() - 1); return d; })();
    const to = toDate ? new Date(toDate) : new Date();
    
    // Convert to ISO 8601 strings and grab objects
    const schedules = await prisma.schedule.findMany({
      where: {
        channel_id: channelId,
        scheduled_at: { gte: from, lte: to }
      },
      orderBy: { scheduled_at: 'asc' }
    });

    if (!schedules.length) return [];

    // Group by iso Week String, compute average diff
    const grouped = {};
    for (const s of schedules) {
      const start = getStartOfWeek(s.scheduled_at);
      const weekLabel = `${start.toLocaleString('en-US', { month: 'short' })} W${Math.ceil(start.getDate() / 7)}`;
      
      const created = new Date(s.created_at);
      const scheduled = new Date(s.scheduled_at);
      const diffMs = scheduled - created;
      const diffDays = diffMs / (1000 * 60 * 60 * 24);
      
      // Filter out weird cases
      if (diffDays >= 0) {
        if (!grouped[weekLabel]) grouped[weekLabel] = { total: 0, count: 0 };
        grouped[weekLabel].total += diffDays;
        grouped[weekLabel].count++;
      }
    }

    return Object.entries(grouped).map(([week, stats]) => ({
      week,
      avgDays: Math.round((stats.total / stats.count) * 10) / 10
    }));
  }

  async getChannelContentMix(channelId, fromDate, toDate) {
    const from = fromDate ? new Date(fromDate) : new Date(0);
    const to = toDate ? new Date(toDate) : new Date('2100-01-01');

    const counts = await prisma.schedule.groupBy({
      by: ['content_type'],
      where: {
        channel_id: channelId,
        scheduled_at: { gte: from, lte: to }
      },
      _count: { _all: true }
    });

    const total = counts.reduce((acc, curr) => acc + curr._count._all, 0);
    if (total === 0) return [];

    return counts.map(c => ({
      contentType: c.content_type,
      count: c._count._all,
      percent: Math.round((c._count._all / total) * 1000) / 10
    })).sort((a, b) => b.count - a.count);
  }

  async getChannelTrend(channelId, days = 7) {
    const now = new Date();
    const periodDays = parseInt(days, 10);
    
    const today = new Date(now);
    today.setHours(0, 0, 0, 0);
    const endCurrent = new Date(today);
    endCurrent.setDate(endCurrent.getDate() + periodDays);

    const startPrevious = new Date(today);
    startPrevious.setDate(startPrevious.getDate() - periodDays);

    const [currentCount, previousCount] = await Promise.all([
      prisma.schedule.count({
        where: {
          channel_id: channelId,
          scheduled_at: { gte: today, lte: endCurrent }
        }
      }),
      prisma.schedule.count({
        where: {
          channel_id: channelId,
          scheduled_at: { gte: startPrevious, lt: today }
        }
      })
    ]);

    let trend = 'flat';
    if (currentCount > previousCount) trend = 'up';
    if (currentCount < previousCount) trend = 'down';

    return { trend, current: currentCount, previous: previousCount };
  }
}

module.exports = new AnalyticsService();
