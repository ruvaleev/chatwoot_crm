import { locale, t } from './i18n';

// Defaults of the team settings (custom Account#crm_settings) until they load.
export const DEFAULT_SETTINGS = {
  overdue_minutes: 10,
  overdue_minutes_off_hours: 60,
  lost_reasons: [],
};
const WEEKDAYS = { Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6, Sun: 7 };
export const MESSAGE_TYPE = { incoming: 0, outgoing: 1, activity: 2 };

const startOfDay = date =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
const DAY = 86400000;

export const waitingMinutes = (waitingSince, now = Date.now()) =>
  waitingSince
    ? Math.max(0, Math.floor((now - waitingSince * 1000) / 60000))
    : 0;

// The day and time where the freelancer is: their schedule's time zone, not the browser's.
const localNow = (timeZone, now) => {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-US', {
      timeZone,
      weekday: 'short',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    })
      .formatToParts(new Date(now))
      .map(part => [part.type, part.value])
  );
  return {
    day: WEEKDAYS[parts.weekday],
    time: `${parts.hour}:${parts.minute}`,
  };
};

// A freelancer's schedule today: whether it is a working day and the hours (Custom::Schedule on the server).
export const scheduleToday = (schedule, now = Date.now()) => {
  if (!schedule) return null;
  const { day, time } = localNow(schedule.time_zone, now);
  const workingDay = schedule.days.includes(day);
  return {
    workingDay,
    workingNow: workingDay && time >= schedule.from && time < schedule.to,
    from: schedule.from,
    to: schedule.to,
  };
};

// A client of a freelancer waits longer before turning red while the freelancer is off;
// without a schedule (or a freelancer) the shorter threshold applies.
export const overdueThreshold = (settings, schedule, now = Date.now()) => {
  const today = scheduleToday(schedule, now);
  return today && !today.workingNow
    ? settings.overdue_minutes_off_hours
    : settings.overdue_minutes;
};

export const isOverdue = (
  chat,
  now = Date.now(),
  settings = DEFAULT_SETTINGS
) =>
  Boolean(chat.waiting_since) &&
  waitingMinutes(chat.waiting_since, now) >=
    overdueThreshold(settings, chat.assignee?.schedule, now);

// For the manager deciding whether to hand a client over today.
export const scheduleLabel = (schedule, now = Date.now()) => {
  const today = scheduleToday(schedule, now);
  if (!today) return t('schedule.none');
  if (!today.workingDay) return t('schedule.day_off');
  return t('schedule.today', { from: today.from, to: today.to });
};

export const waitingLabel = minutes =>
  minutes < 60
    ? t('wait.minutes', { n: minutes })
    : t('wait.hours', { n: Math.floor(minutes / 60) });

export const clock = unix =>
  new Intl.DateTimeFormat(locale.value, {
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(unix * 1000));

// Like a chat list: time today, "Yesterday", then a short date.
export const listTime = (unix, now = new Date()) => {
  if (!unix) return '';
  const date = new Date(unix * 1000);
  const days = Math.round((startOfDay(now) - startOfDay(date)) / DAY);
  if (days === 0) return clock(unix);
  if (days === 1) return t('time.yesterday');
  return new Intl.DateTimeFormat(locale.value, {
    day: 'numeric',
    month: 'short',
  }).format(date);
};

export const dayLabel = (unix, now = new Date()) => {
  const date = new Date(unix * 1000);
  const days = Math.round((startOfDay(now) - startOfDay(date)) / DAY);
  if (days === 0) return t('day.today');
  if (days === 1) return t('day.yesterday');
  return new Intl.DateTimeFormat(locale.value, {
    day: 'numeric',
    month: 'long',
  }).format(date);
};

export const sameDay = (a, b) =>
  startOfDay(new Date(a * 1000)) === startOfDay(new Date(b * 1000));

const previewKind = type =>
  ['image', 'video', 'audio'].includes(type) ? type : 'file';

export const previewText = lastMessage => {
  if (!lastMessage) return t('preview.empty');
  if (lastMessage.content) return lastMessage.content;
  if (!lastMessage.attachment_type) return '';
  const key = `preview.${previewKind(lastMessage.attachment_type)}`;
  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys -- our own t(), keys are in locales/
  return t(key);
};

// Evolution picks WhatsApp's message type from the file extension of the attachment URL, so a recording must end in
// an audio extension it knows. Chrome records webm/opus: named .ogg it is sent as a voice note (Evolution converts it).
export const voiceFileName = mimeType =>
  mimeType.includes('mp4') ? 'voice.m4a' : 'voice.ogg';

export const fileSize = bytes => {
  if (!bytes) return '';
  if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
};

export const initials = name =>
  (name || '')
    .split(/\s+/)
    .filter(word => /^\p{L}/u.test(word))
    .slice(0, 2)
    .map(word => word[0].toUpperCase())
    .join('');

const TEMPLATE_SUGGESTIONS = 8;

// Templates typed as "/query": matched by short code or text.
export const matchTemplates = (templates, query) =>
  templates
    .filter(template =>
      `${template.short_code} ${template.content}`
        .toLowerCase()
        .includes(query.toLowerCase())
    )
    .slice(0, TEMPLATE_SUGGESTIONS);
