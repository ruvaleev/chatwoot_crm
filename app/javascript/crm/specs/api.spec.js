import { request, setUnauthorizedHandler } from '../lib/api';

const reply = status => ({
  ok: status < 400,
  status,
  json: () => Promise.resolve({ error: 'denied' }),
});

describe('request', () => {
  const signedOut = vi.fn();

  beforeEach(() => {
    signedOut.mockReset();
    setUnauthorizedHandler(signedOut);
  });

  it('keeps the session when only the record is off limits', async () => {
    global.fetch = vi.fn(url =>
      Promise.resolve(
        reply(String(url).endsWith('/api/v1/profile') ? 200 : 401)
      )
    );

    await expect(
      request('/api/v1/accounts/1/conversations/5/messages')
    ).rejects.toThrow();
    expect(signedOut).not.toHaveBeenCalled();
  });

  it('signs out when the session has expired', async () => {
    global.fetch = vi.fn(() => Promise.resolve(reply(401)));

    await expect(request('/api/v1/accounts/1/crm/chats')).rejects.toThrow();
    expect(signedOut).toHaveBeenCalledOnce();
  });
});
