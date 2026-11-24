import { describe, it, expect, afterEach } from 'vitest';
import { errorKey, LOCALES, setLocale, t } from '../lib/i18n';

describe('i18n', () => {
  afterEach(() => setLocale('ru'));

  it('has the same keys in every language', () => {
    const [first, ...others] = Object.values(LOCALES).map(dictionary =>
      Object.keys(dictionary).sort()
    );
    others.forEach(keys => expect(keys).toEqual(first));
  });

  it('switches language and fills placeholders', () => {
    setLocale('en');
    expect(t('chat.brief_by', { name: 'Anna' })).toBe('Brief from Anna');
    setLocale('ru');
    expect(t('chat.brief_by', { name: 'Анна' })).toBe('Бриф · Анна');
  });

  it('falls back to Russian for an unknown language', () => {
    setLocale('xx');
    expect(t('nav.chats')).toBe('Чаты');
  });

  it('shows server error codes in the interface language, anything else as a generic failure', () => {
    expect(errorKey({ status: 422, message: 'login_taken' })).toBe(
      'errors.login_taken'
    );
    expect(errorKey({ status: 422, message: 'Something in English' })).toBe(
      'error.generic'
    );
    expect(errorKey({ status: 500, message: 'login_taken' })).toBe(
      'error.generic'
    );
    expect(errorKey(new Error('offline'))).toBe('error.generic');
  });
});
