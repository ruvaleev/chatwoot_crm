// CRM: our handler in actionCable.js (crm/docs/core-changes.md); kept apart from the upstream spec.
import { describe, it, beforeEach, expect, vi } from 'vitest';
import ActionCableConnector from '../actionCable';
import { emitter } from 'shared/helpers/mitt';

const { push } = vi.hoisted(() => ({ push: vi.fn() }));
vi.mock('dashboard/routes', () => ({ router: { push } }));
vi.mock('shared/helpers/mitt', () => ({ emitter: { emit: vi.fn() } }));
vi.mock('dashboard/composables/useImpersonation', () => ({
  useImpersonation: () => ({ isImpersonating: { value: false } }),
}));

global.chatwootConfig = { websocketURL: 'wss://test.chatwoot.com' };

describe('conversation.crm_access_revoked', () => {
  let store;
  let actionCable;

  const revoke = id =>
    actionCable.events['conversation.crm_access_revoked']({ id });

  beforeEach(() => {
    vi.clearAllMocks();
    store = {
      commit: vi.fn(),
      dispatch: vi.fn(),
      getters: {
        getCurrentAccountId: 1,
        getSelectedChat: { id: 7 },
        'accounts/isFeatureEnabledonAccount': vi.fn(() => true),
      },
    };
    actionCable = ActionCableConnector.init(store, 'test-token');
  });

  it('drops the conversation from the list and refreshes the counters', async () => {
    await revoke(3);

    expect(store.commit).toHaveBeenCalledWith('DELETE_CONVERSATION', 3);
    expect(emitter.emit).toHaveBeenCalledWith('fetch_conversation_stats');
    expect(push).not.toHaveBeenCalled();
  });

  it('leaves the open conversation for the conversation list', async () => {
    await revoke(7);

    expect(push).toHaveBeenCalledWith('/app/accounts/1/dashboard');
  });
});
