// Push notifications on this device (crm/PRD.md, stage P). The service worker (public/crm/sw.js) shows them and
// opens the chat on tap; the server sends them (Custom::Push). On iPhone this works only once the app is added to
// the home screen.
import { ref } from 'vue';
import { removePushSubscription, savePushSubscription } from './store';

// unsupported | denied | off | on, shared by the settings and the banner over the chat list.
export const push = ref('off');
// "Later" on the banner: until the app is opened again.
export const pushBannerHidden = ref(false);

const supported = () =>
  'serviceWorker' in navigator &&
  'PushManager' in window &&
  'Notification' in window;

// The server's VAPID public key, base64url in a meta tag of the page; the browser wants its bytes.
const serverKey = () => {
  const key = document.querySelector('meta[name="crm-vapid-key"]').content;
  const base64 = key.replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(base64), char => char.charCodeAt(0));
};

const currentSubscription = async () => {
  const registration = await navigator.serviceWorker.ready;
  return registration.pushManager.getSubscription();
};

export const registerWorker = () => {
  if (supported()) navigator.serviceWorker.register('/crm/sw.js');
};

const currentState = async () => {
  if (!supported()) return 'unsupported';
  if (Notification.permission === 'denied') return 'denied';
  if (Notification.permission !== 'granted') return 'off';
  return (await currentSubscription()) ? 'on' : 'off';
};

export const refreshPush = async () => {
  push.value = await currentState();
};

// Asks for permission: browsers allow it only from a tap.
export const enablePush = async () => {
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    push.value = permission === 'denied' ? 'denied' : 'off';
    return;
  }

  const registration = await navigator.serviceWorker.ready;
  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: serverKey(),
  });
  const { endpoint, keys } = subscription.toJSON();
  await savePushSubscription({
    endpoint,
    p256dh: keys.p256dh,
    auth: keys.auth,
  });
  push.value = 'on';
};

// On sign-out too: the next person on this device must not get these notifications.
export const disablePush = async () => {
  if (!supported()) return;
  const subscription = await currentSubscription();
  if (!subscription) return;
  await removePushSubscription(subscription.endpoint);
  await subscription.unsubscribe();
  push.value = 'off';
};
