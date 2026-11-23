<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import { signIn } from '../lib/api';
import { t } from '../lib/i18n';

const router = useRouter();
const email = ref('');
const password = ref('');
const failed = ref(false);
const busy = ref(false);

const submit = async () => {
  busy.value = true;
  failed.value = false;
  try {
    await signIn(email.value.trim(), password.value);
    router.replace({ name: 'chats' });
  } catch {
    failed.value = true;
  } finally {
    busy.value = false;
  }
};
</script>

<template>
  <main class="flex min-h-full items-center justify-center bg-app px-4 py-10">
    <form
      class="w-full max-w-sm rounded-2xl bg-panel p-6 shadow-pop"
      @submit.prevent="submit"
    >
      <h1 class="mb-6 text-2xl font-semibold">{{ t('login.title') }}</h1>
      <label class="mb-4 block">
        <span class="mb-1.5 block text-sm text-muted">{{
          t('login.email')
        }}</span>
        <input
          v-model="email"
          type="text"
          autocomplete="username"
          autocapitalize="none"
          required
          class="w-full rounded-lg border border-line bg-panel px-3 py-2.5 outline-none focus:border-accent"
        />
      </label>
      <label class="mb-4 block">
        <span class="mb-1.5 block text-sm text-muted">{{
          t('login.password')
        }}</span>
        <input
          v-model="password"
          type="password"
          autocomplete="current-password"
          required
          class="w-full rounded-lg border border-line bg-panel px-3 py-2.5 outline-none focus:border-accent"
        />
      </label>
      <p
        v-if="failed"
        class="mb-4 rounded-lg bg-danger-soft px-3 py-2 text-sm text-danger"
      >
        {{ t('login.failed') }}
      </p>
      <button
        type="submit"
        :disabled="busy"
        class="w-full rounded-lg bg-accent px-4 py-2.5 font-medium text-on-accent hover:bg-accent-strong disabled:opacity-60"
      >
        {{ t('login.submit') }}
      </button>
    </form>
  </main>
</template>
