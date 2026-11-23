import { authHeaders, clearSession, saveSession } from './session';

export class ApiError extends Error {
  constructor(status, body) {
    super(body?.message || body?.error || `HTTP ${status}`);
    this.status = status;
  }
}

let onUnauthorized = () => {};
export const setUnauthorizedHandler = handler => {
  onUnauthorized = handler;
};

export const request = async (path, { method = 'GET', body, query } = {}) => {
  const url = new URL(path, window.location.origin);
  Object.entries(query || {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null) url.searchParams.set(key, value);
  });
  const headers = { Accept: 'application/json', ...authHeaders() };
  const isForm = body instanceof FormData;
  if (body && !isForm) headers['Content-Type'] = 'application/json';

  const response = await fetch(url, {
    method,
    headers,
    body: isForm || !body ? body : JSON.stringify(body),
  });
  if (response.status === 401) {
    clearSession();
    onUnauthorized();
  }
  const data =
    response.status === 204 ? null : await response.json().catch(() => null);
  if (!response.ok) throw new ApiError(response.status, data);
  return data;
};

// Freelancers get a short login; the server stores it as an email on this reserved domain.
export const LOGIN_DOMAIN = 'crm.invalid';
const loginEmail = login =>
  login.includes('@') ? login : `${login}@${LOGIN_DOMAIN}`;

export const signIn = async (login, password) => {
  const email = loginEmail(login);
  const response = await fetch('/auth/sign_in', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  if (!response.ok)
    throw new ApiError(
      response.status,
      await response.json().catch(() => null)
    );
  saveSession(response.headers);
};

export const signOut = async () => {
  await request('/auth/sign_out', { method: 'DELETE' }).catch(() => null);
  clearSession();
};

export const accountApi = accountId => {
  const base = `/api/v1/accounts/${accountId}`;
  return {
    chats: query => request(`${base}/crm/chats`, { query }),
    chat: id => request(`${base}/crm/chats/${id}`),
    updateChat: (id, body) =>
      request(`${base}/crm/chats/${id}`, { method: 'PATCH', body }),
    hide: id => request(`${base}/crm/chats/${id}/hide`, { method: 'POST' }),
    handoff: (id, body) =>
      request(`${base}/crm/chats/${id}/handoff`, { method: 'POST', body }),
    templates: () => request(`${base}/canned_responses`),
    numbers: () => request(`${base}/crm/numbers`),
    addNumber: name =>
      request(`${base}/crm/numbers`, { method: 'POST', body: { name } }),
    connectNumber: id =>
      request(`${base}/crm/numbers/${id}/connect`, { method: 'POST' }),
    assignNumber: (id, freelancerId) =>
      request(`${base}/crm/numbers/${id}`, {
        method: 'PATCH',
        body: { freelancer_id: freelancerId },
      }),
    restartNumber: id =>
      request(`${base}/crm/numbers/${id}/restart`, { method: 'POST' }),
    logoutNumber: id =>
      request(`${base}/crm/numbers/${id}/logout`, { method: 'POST' }),
    freelancers: () => request(`${base}/crm/freelancers`),
    addFreelancer: body =>
      request(`${base}/crm/freelancers`, { method: 'POST', body }),
    moveFreelancer: (id, numberId) =>
      request(`${base}/crm/freelancers/${id}`, {
        method: 'PATCH',
        body: { number_id: numberId },
      }),
    inviteFreelancer: id =>
      request(`${base}/crm/freelancers/${id}/invite`, { method: 'POST' }),
    removeFreelancer: id =>
      request(`${base}/crm/freelancers/${id}`, { method: 'DELETE' }),
    unhide: id => request(`${base}/crm/chats/${id}/hide`, { method: 'DELETE' }),
    messages: (id, before) =>
      request(`${base}/conversations/${id}/messages`, { query: { before } }),
    send: (id, body) =>
      request(`${base}/conversations/${id}/messages`, { method: 'POST', body }),
    retry: (id, messageId) =>
      request(`${base}/conversations/${id}/messages/${messageId}/retry`, {
        method: 'POST',
      }),
    markRead: id =>
      request(`${base}/conversations/${id}/update_last_seen`, {
        method: 'POST',
      }),
    labels: () => request(`${base}/labels`),
    setContactLabels: (contactId, labels) =>
      request(`${base}/contacts/${contactId}/labels`, {
        method: 'POST',
        body: { labels },
      }),
    renameContact: (contactId, name) =>
      request(`${base}/contacts/${contactId}`, {
        method: 'PATCH',
        body: { name },
      }),
  };
};

export const profileApi = {
  get: () => request('/api/v1/profile'),
  saveUiSettings: uiSettings =>
    request('/api/v1/profile', {
      method: 'PUT',
      body: { profile: { ui_settings: uiSettings } },
    }),
};

// The sign-in link: no session yet, the token is the credential.
export const invitationApi = {
  get: token => request(`/api/v1/crm/invitations/${token}`),
  accept: (token, password, confirmation) =>
    request(`/api/v1/crm/invitations/${token}`, {
      method: 'POST',
      body: { password, password_confirmation: confirmation },
    }),
};
