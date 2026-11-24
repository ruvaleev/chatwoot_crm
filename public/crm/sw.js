/* eslint-disable no-restricted-globals */
/* globals clients */
// Service worker of the CRM interface (crm/PRD.md, stage P), scope /crm/. Shows push notifications of new client
// messages (Custom::Push) and opens the chat on tap. No offline cache: the chats are live data.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(clients.claim()));

self.addEventListener('push', event => {
  const { title, body, tag, url } = event.data.json();
  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      tag,
      renotify: true,
      icon: '/crm/icon-192.png',
      badge: '/crm/icon-192.png',
      data: { url },
    })
  );
});

// An open window of the app goes to the chat; otherwise a new one opens there.
self.addEventListener('notificationclick', event => {
  event.notification.close();
  const { url } = event.notification.data;
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windows => {
      const open = windows.find(client =>
        new URL(client.url).pathname.startsWith('/crm')
      );
      if (!open) return clients.openWindow(url);
      return open.focus().then(client => client.navigate(url));
    })
  );
});
