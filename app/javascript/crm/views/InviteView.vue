<script setup>
import { onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { invitationApi, signIn } from '../lib/api';
import { clearSession } from '../lib/session';
import { reset } from '../lib/store';
import { t } from '../lib/i18n';

const route = useRoute();
const router = useRouter();

const invitation = ref(null);
const broken = ref(false);
const password = ref('');
const confirmation = ref('');
const error = ref('');
const busy = ref(false);

onMounted(async () => {
  try {
    invitation.value = await invitationApi.get(route.params.token);
  } catch {
    broken.value = true;
  }
});

const submit = async () => {
  error.value = '';
  if (password.value !== confirmation.value) {
    error.value = t('invite.mismatch');
    return;
  }
  busy.value = true;
  try {
    const { login } = await invitationApi.accept(
      route.params.token,
      password.value,
      confirmation.value
    );
    // Whoever was signed in on this device before, the link is for this freelancer.
    reset();
    clearSession();
    await signIn(login, password.value);
    router.replace({ name: 'chats' });
  } catch (failure) {
    error.value = t(failure.status === 422 ? 'invite.weak' : 'error.generic');
  } finally {
    busy.value = false;
  }
};
</script>

<template>
  <main class="flex min-h-full items-center justify-center bg-app px-4 py-10">
    <section class="w-full max-w-sm rounded-2xl bg-panel p-6 shadow-pop">
      <template v-if="broken">
        <span class="i-lucide-link-2-off mb-3 size-10 text-faint" />
        <h1 class="mb-2 text-xl font-semibold">{{ t('invite.broken') }}</h1>
        <p class="text-sm text-muted">{{ t('invite.broken_text') }}</p>
      </template>
      <div
        v-else-if="!invitation"
        class="flex justify-center py-6"
        aria-busy="true"
      >
        <span class="i-lucide-loader-circle size-6 animate-spin text-faint" />
      </div>
      <form v-else @submit.prevent="submit">
        <h1 class="mb-1 text-xl font-semibold">
          {{ t('invite.title', { name: invitation.name }) }}
        </h1>
        <p class="mb-6 text-sm text-muted">
          {{ t('invite.login', { login: invitation.login }) }}
        </p>
        <label class="mb-4 block">
          <span class="mb-1.5 block text-sm text-muted">
            {{ t('invite.password') }}
          </span>
          <input
            v-model="password"
            type="password"
            autocomplete="new-password"
            required
            class="w-full rounded-lg border border-line bg-panel px-3 py-2.5 outline-none focus:border-accent"
          />
        </label>
        <label class="mb-2 block">
          <span class="mb-1.5 block text-sm text-muted">
            {{ t('invite.confirmation') }}
          </span>
          <input
            v-model="confirmation"
            type="password"
            autocomplete="new-password"
            required
            class="w-full rounded-lg border border-line bg-panel px-3 py-2.5 outline-none focus:border-accent"
          />
        </label>
        <p class="mb-4 text-xs text-faint">{{ t('invite.rules') }}</p>
        <p
          v-if="error"
          class="mb-4 rounded-lg bg-danger-soft px-3 py-2 text-sm text-danger"
        >
          {{ error }}
        </p>
        <button
          type="submit"
          class="w-full rounded-lg bg-accent px-4 py-2.5 font-medium text-on-accent hover:bg-accent-strong disabled:opacity-60"
          :disabled="busy"
        >
          {{ t('invite.submit') }}
        </button>
      </form>
    </section>
  </main>
</template>
