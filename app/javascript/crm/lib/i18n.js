// A tiny dictionary lookup instead of vue-i18n: the app needs only plain strings with {placeholders},
// and every kilobyte counts against the bundle budget (crm/PRD.md, AC D.8).
import { ref } from 'vue';
import ru from '../locales/ru';
import en from '../locales/en';

export const LOCALES = { ru, en };
export const DEFAULT_LOCALE = 'ru';

export const locale = ref(DEFAULT_LOCALE);

export const setLocale = value => {
  locale.value = LOCALES[value] ? value : DEFAULT_LOCALE;
  document.documentElement.lang = locale.value;
};

export const t = (key, params = {}) => {
  const text =
    LOCALES[locale.value][key] ?? LOCALES[DEFAULT_LOCALE][key] ?? key;
  return text.replace(/\{(\w+)\}/g, (match, name) =>
    name in params ? params[name] : match
  );
};

// Our endpoints answer 422 with an error code; its text lives here. Anything else reads as a generic failure.
export const errorKey = failure => {
  const key = `errors.${failure?.message}`;
  return failure?.status === 422 && key in LOCALES[DEFAULT_LOCALE]
    ? key
    : 'error.generic';
};
