import { createRouter, createWebHistory } from 'vue-router';
import { boot, isManager, isSignedIn, state } from './lib/store';
import LoginView from './views/LoginView.vue';
import InviteView from './views/InviteView.vue';
import ChatsLayout from './views/ChatsLayout.vue';

const router = createRouter({
  history: createWebHistory('/crm/'),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: { public: true },
    },
    { path: '/', name: 'chats', component: ChatsLayout },
    { path: '/hidden', name: 'hidden', component: ChatsLayout },
    { path: '/settings', name: 'settings', component: ChatsLayout },
    {
      path: '/numbers',
      name: 'numbers',
      component: ChatsLayout,
      meta: { manager: true },
    },
    {
      path: '/freelancers',
      name: 'freelancers',
      component: ChatsLayout,
      meta: { manager: true },
    },
    {
      path: '/team',
      name: 'team',
      component: ChatsLayout,
      meta: { manager: true },
    },
    {
      path: '/invite/:token',
      name: 'invite',
      component: InviteView,
      meta: { public: true, invite: true },
    },
    { path: '/chats/:id(\\d+)', name: 'chat', component: ChatsLayout },
    { path: '/:pathMatch(.*)*', redirect: { name: 'chats' } },
  ],
});

router.beforeEach(async to => {
  // A sign-in link opens even with someone already signed in on this device.
  if (to.meta.invite) return true;
  if (to.meta.public) return isSignedIn() ? { name: 'chats' } : true;
  if (!isSignedIn()) return { name: 'login' };
  if (!state.ready) await boot(router);
  if (to.meta.manager && !isManager.value) return { name: 'chats' };
  return true;
});

export default router;
