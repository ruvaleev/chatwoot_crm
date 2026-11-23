import { describe, it, expect, beforeEach } from 'vitest';
import {
  initials,
  isOverdue,
  listTime,
  matchTemplates,
  previewText,
  voiceFileName,
  waitingLabel,
  waitingMinutes,
} from '../lib/format';
import { setLocale } from '../lib/i18n';

const NOW = new Date(2026, 10, 23, 15, 0).getTime();
const minutesAgo = minutes => Math.floor((NOW - minutes * 60000) / 1000);

describe('waiting for a reply', () => {
  beforeEach(() => setLocale('ru'));

  it('counts minutes since the client wrote', () => {
    expect(waitingMinutes(minutesAgo(12), NOW)).toBe(12);
    expect(waitingMinutes(null, NOW)).toBe(0);
  });

  it('marks a chat red from ten minutes on', () => {
    expect(isOverdue({ waiting_since: minutesAgo(9) }, NOW)).toBe(false);
    expect(isOverdue({ waiting_since: minutesAgo(10) }, NOW)).toBe(true);
    expect(isOverdue({ waiting_since: null }, NOW)).toBe(false);
  });

  it('switches to hours after an hour', () => {
    expect(waitingLabel(14)).toBe('14 мин');
    expect(waitingLabel(130)).toBe('2 ч');
  });
});

describe('list time', () => {
  beforeEach(() => setLocale('ru'));

  it('shows the clock today, "yesterday", then a date', () => {
    const now = new Date(NOW);
    expect(listTime(minutesAgo(30), now)).toBe('14:30');
    expect(listTime(minutesAgo(24 * 60), now)).toBe('Вчера');
    expect(listTime(minutesAgo(5 * 24 * 60), now)).toMatch(/18/);
  });
});

describe('previews and files', () => {
  beforeEach(() => setLocale('en'));

  it('names an attachment when the message has no text', () => {
    expect(previewText({ content: '', attachment_type: 'audio' })).toBe(
      'Voice message'
    );
    expect(previewText({ content: '', attachment_type: 'file' })).toBe(
      'Document'
    );
    expect(previewText({ content: 'hi', attachment_type: 'image' })).toBe('hi');
    expect(previewText(null)).toBe('No messages');
  });

  it('gives recordings an audio extension Evolution sends as a voice note', () => {
    expect(voiceFileName('audio/webm;codecs=opus')).toBe('voice.ogg');
    expect(voiceFileName('audio/ogg')).toBe('voice.ogg');
    expect(voiceFileName('audio/mp4')).toBe('voice.m4a');
  });

  it('builds initials from words only', () => {
    expect(initials('Анна Ветрова')).toBe('АВ');
    expect(initials('Client •••49')).toBe('C');
    expect(initials('')).toBe('');
  });
});

describe('templates', () => {
  const templates = [
    { id: 1, short_code: 'hello', content: 'Hi! How can I help?' },
    { id: 2, short_code: 'price', content: 'Prices start at 100' },
  ];

  it('matches the short code or the text, case-insensitively', () => {
    expect(matchTemplates(templates, 'HEL').map(t => t.id)).toEqual([1]);
    expect(matchTemplates(templates, 'start').map(t => t.id)).toEqual([2]);
    expect(matchTemplates(templates, '').map(t => t.id)).toEqual([1, 2]);
  });
});
