// The same sign-in cookie as the old dashboard, so one login works in both during the transition (stage D4).
import Cookies from 'js-cookie';

const COOKIE = 'cw_d_session_info';
const AUTH_HEADERS = ['access-token', 'client', 'uid', 'token-type', 'expiry'];

export const readSession = () => {
  try {
    return JSON.parse(Cookies.get(COOKIE) || 'null');
  } catch {
    return null;
  }
};

export const saveSession = headers => {
  const session = Object.fromEntries(
    AUTH_HEADERS.map(name => [name, headers.get(name)])
  );
  const days = Math.max(
    1,
    Math.floor((Number(session.expiry) * 1000 - Date.now()) / 86400000)
  );
  Cookies.set(COOKIE, JSON.stringify(session), {
    expires: days,
    sameSite: 'Lax',
  });
};

export const clearSession = () => Cookies.remove(COOKIE);

export const authHeaders = () => {
  const session = readSession();
  if (!session) return {};
  return {
    'access-token': session['access-token'],
    client: session.client,
    uid: session.uid,
  };
};
