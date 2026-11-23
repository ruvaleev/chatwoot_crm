// App state in plain reactive objects (no store library: crm/PRD.md, AC D.8). Every server call made here is one
// the open screen needs; afterwards the screen is kept fresh by WebSocket events only.
import { computed, reactive, ref } from 'vue';
import { accountApi, profileApi, setUnauthorizedHandler } from './api';
import { connectCable } from './cable';
import { readSession } from './session';
import { setLocale, t } from './i18n';
import { MESSAGE_TYPE } from './format';

const LIST_EVENTS = [
  'conversation.created',
  'conversation.updated',
  'conversation.status_changed',
  'conversation.read',
  'assignee.changed',
];
const REFRESH_DELAY = 400;
const TOAST_TIME = 3000;

export const state = reactive({
  ready: false,
  user: null,
  accountId: null,
  uiSettings: {},
  list: {
    filter: 'all',
    inboxId: null,
    status: null,
    sort: 'recent',
    query: '',
    items: [],
    counts: { waiting: 0, new: 0, mine: 0, hidden: 0 },
    inboxes: [],
    page: 1,
    hasMore: false,
    loading: false,
  },
  chat: {
    id: null,
    header: null,
    messages: [],
    hasOlder: false,
    loading: false,
  },
  toast: null,
});
export const now = ref(Date.now());
export const isManager = computed(
  () => state.user?.custom_attributes?.crm_freelancer !== true
);

let api = null;
let router = null;
let disconnect = null;
let refreshTimer = null;
let toastTimer = null;
let clockTimer = null;
let listRequest = 0;
let templates = null;

export const toast = key => {
  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys -- our own t(), keys are in locales/
  state.toast = t(key);
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    state.toast = null;
  }, TOAST_TIME);
};

export const applyTheme = theme => {
  if (theme === 'light' || theme === 'dark')
    document.documentElement.dataset.theme = theme;
  else delete document.documentElement.dataset.theme;
};

export const isSignedIn = () => Boolean(readSession());

// ---------- chat list ----------

const listQuery = (page = 1) => {
  const { list } = state;
  return {
    filter: list.filter,
    sort: list.sort,
    inbox_id: list.inboxId,
    status: list.status,
    q: list.query.trim() || null,
    page,
  };
};

// Every list request carries the current tab and filters; a slower, older answer is dropped.
export const loadList = async (changes = {}) => {
  const { list } = state;
  Object.assign(list, changes);
  listRequest += 1;
  const request = listRequest;
  list.loading = true;
  try {
    const data = await api.chats(listQuery());
    if (request !== listRequest) return;
    Object.assign(list, {
      items: data.payload,
      counts: {
        waiting: data.meta.waiting_count,
        new: data.meta.new_count,
        mine: data.meta.mine_count,
        hidden: data.meta.hidden_count,
      },
      inboxes: data.meta.inboxes,
      page: 1,
      hasMore: data.meta.has_more,
    });
  } finally {
    if (request === listRequest) list.loading = false;
  }
};

export const loadMore = async () => {
  const { list } = state;
  if (!list.hasMore || list.loading) return;
  list.loading = true;
  try {
    const data = await api.chats(listQuery(list.page + 1));
    list.items.push(
      ...data.payload.filter(
        row => !list.items.some(item => item.id === row.id)
      )
    );
    list.page += 1;
    list.hasMore = data.meta.has_more;
  } finally {
    list.loading = false;
  }
};

const scheduleListRefresh = () => {
  clearTimeout(refreshTimer);
  refreshTimer = setTimeout(() => loadList(), REFRESH_DELAY);
};

const patchRow = (id, changes) => {
  const row = state.list.items.find(item => item.id === id);
  if (row) Object.assign(row, changes);
};

const dropRow = id => {
  state.list.items = state.list.items.filter(item => item.id !== id);
};

// ---------- open chat ----------

const markRead = id => {
  patchRow(id, { unread_count: 0 });
  api.markRead(id).catch(() => null);
};

export const openChat = async id => {
  const { chat } = state;
  if (chat.id !== id)
    Object.assign(chat, { id, header: null, messages: [], hasOlder: false });
  chat.loading = true;
  try {
    const [header, messages] = await Promise.all([
      api.chat(id),
      api.messages(id),
    ]);
    if (chat.id !== id) return;
    chat.header = header;
    chat.messages = messages.payload;
    chat.hasOlder = messages.payload.length > 0;
    markRead(id);
  } finally {
    chat.loading = false;
  }
};

export const closeChat = () => {
  Object.assign(state.chat, {
    id: null,
    header: null,
    messages: [],
    hasOlder: false,
  });
};

export const loadOlder = async () => {
  const { chat } = state;
  const first = chat.messages.find(message => typeof message.id === 'number');
  if (!first || !chat.hasOlder) return;
  const id = chat.id;
  const data = await api.messages(id, first.id);
  if (chat.id !== id) return;
  chat.messages = [...data.payload, ...chat.messages];
  chat.hasOlder = data.payload.length > 0;
};

const upsertMessage = message => {
  const { messages } = state.chat;
  const index = messages.findIndex(
    item =>
      item.id === message.id ||
      (message.echo_id && item.echo_id === message.echo_id)
  );
  if (index === -1) messages.push(message);
  else messages[index] = { ...messages[index], ...message };
};

const fileKind = file => {
  const [kind] = file.type.split('/');
  return ['image', 'video', 'audio'].includes(kind) ? kind : 'file';
};

const optimistic = ({ content, isPrivate, files = [] }) => {
  const echoId = `crm-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  upsertMessage({
    id: echoId,
    echo_id: echoId,
    content,
    private: isPrivate,
    message_type: MESSAGE_TYPE.outgoing,
    status: 'progress',
    created_at: Math.floor(Date.now() / 1000),
    sender: { id: state.user.id, name: state.user.name, type: 'user' },
    attachments: files.map(file => ({
      file_type: fileKind(file),
      data_url: URL.createObjectURL(file),
      extension: file.name.split('.').pop(),
    })),
  });
  return echoId;
};

export const sendMessage = async ({
  content = '',
  isPrivate = false,
  files = [],
}) => {
  const id = state.chat.id;
  const echoId = optimistic({ content, isPrivate, files });
  let body;
  if (files.length) {
    body = new FormData();
    body.append('content', content);
    body.append('private', isPrivate);
    body.append('echo_id', echoId);
    files.forEach(file => body.append('attachments[]', file, file.name));
  } else {
    body = { content, private: isPrivate, echo_id: echoId };
  }
  try {
    const message = await api.send(id, body);
    if (state.chat.id === id) upsertMessage({ ...message, echo_id: echoId });
  } catch {
    if (state.chat.id === id)
      upsertMessage({ echo_id: echoId, status: 'failed' });
  }
};

export const retryMessage = async message => {
  if (typeof message.id !== 'number') return;
  upsertMessage({ id: message.id, status: 'progress' });
  await api
    .retry(state.chat.id, message.id)
    .catch(() => upsertMessage({ id: message.id, status: 'failed' }));
};

// ---------- chat actions ----------

const updateHeader = changes => {
  if (state.chat.header) Object.assign(state.chat.header, changes);
};

export const setHidden = async (id, hidden) => {
  await (hidden ? api.hide(id) : api.unhide(id));
  updateHeader({ hidden });
  toast(hidden ? 'toast.hidden' : 'toast.unhidden');
  loadList();
};

export const updateDeal = async (id, changes) => {
  const header = await api.updateChat(id, changes);
  updateHeader(header);
  patchRow(id, { status: header.status });
};

export const handoff = async brief => {
  const id = state.chat.id;
  const header = await api.handoff(id, { brief });
  if (state.chat.id === id) updateHeader(header);
  patchRow(id, { status: header.status, assignee: header.assignee });
};

// Team templates, loaded once on the first "/" typed in the composer.
export const fetchTemplates = async () => {
  templates ??= await api.templates();
  return templates;
};

export const fetchLabels = async () =>
  (await api.labels()).payload.map(label => label.title);

export const setContactLabels = async labels => {
  const contact = state.chat.header.contact;
  await api.setContactLabels(contact.id, labels);
  contact.labels = labels;
  patchRow(state.chat.id, { contact: { ...contact } });
};

export const renameContact = async name => {
  const contact = state.chat.header.contact;
  await api.renameContact(contact.id, name);
  contact.name = name;
  patchRow(state.chat.id, { contact: { ...contact } });
};

// ---------- real-time ----------

const openChatHeader = async id => {
  const header = await api.chat(id).catch(() => null);
  if (header && state.chat.id === id) state.chat.header = header;
};

const handleEvent = (event, data) => {
  if (event === 'message.created' || event === 'message.updated') {
    if (data.conversation_id === state.chat.id) {
      upsertMessage(data);
      if (
        event === 'message.created' &&
        data.message_type === MESSAGE_TYPE.incoming
      )
        markRead(state.chat.id);
    }
    scheduleListRefresh();
  } else if (event === 'conversation.crm_access_revoked') {
    dropRow(data.id);
    if (data.id === state.chat.id) {
      closeChat();
      toast('chat.revoked');
      router.replace({ name: 'chats' });
    }
  } else if (LIST_EVENTS.includes(event)) {
    scheduleListRefresh();
    const status = data.custom_attributes?.crm_status;
    if (data.id === state.chat.id && status) updateHeader({ status });
    if (data.id === state.chat.id && event === 'assignee.changed')
      openChatHeader(data.id);
  }
};

// ---------- session ----------

export const reset = () => {
  disconnect?.();
  disconnect = null;
  clearInterval(clockTimer);
  state.ready = false;
  state.user = null;
};

export const saveSettings = async changes => {
  state.uiSettings = { ...state.uiSettings, ...changes };
  if (changes.crm_locale) setLocale(changes.crm_locale);
  if ('crm_theme' in changes) applyTheme(changes.crm_theme);
  await profileApi.saveUiSettings(state.uiSettings);
};

export const boot = async appRouter => {
  router = appRouter;
  setUnauthorizedHandler(() => {
    reset();
    router.replace({ name: 'login' });
  });
  const profile = await profileApi.get();
  state.user = profile;
  state.accountId = profile.account_id || profile.accounts[0].id;
  state.uiSettings = profile.ui_settings || {};
  state.list.sort = state.uiSettings.crm_sort || 'recent';
  setLocale(
    state.uiSettings.crm_locale ||
      (navigator.language.startsWith('ru') ? 'ru' : 'en')
  );
  applyTheme(state.uiSettings.crm_theme);
  api = accountApi(state.accountId);
  disconnect = connectCable({
    pubsubToken: profile.pubsub_token,
    accountId: state.accountId,
    userId: profile.id,
    onEvent: handleEvent,
    onReconnect: () => {
      loadList();
      if (state.chat.id) openChat(state.chat.id);
    },
  });
  clockTimer = setInterval(() => {
    now.value = Date.now();
  }, 30000);
  state.ready = true;
};

export const setSort = async sort => {
  await loadList({ sort });
  await saveSettings({ crm_sort: sort });
};
