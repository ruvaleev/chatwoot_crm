<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import BottomSheet from './BottomSheet.vue';
import { t } from '../lib/i18n';
import {
  addNumber,
  assignNumber,
  connectNumber,
  fetchNumbers,
  logoutNumber,
  toast,
} from '../lib/store';

const router = useRouter();

// Only while a QR code is on screen: has the phone linked, and a fresh code before WhatsApp expires it.
const STATE_POLL = 5000;
const QR_REFRESH = 30000;
const STATE_TONES = {
  open: 'bg-ok-soft text-ok',
  connecting: 'bg-warn-soft text-warn',
  close: 'bg-danger-soft text-danger',
  unknown: 'bg-chip text-muted',
};

const numbers = ref([]);
const freelancers = ref([]);
const loading = ref(true);
const adding = ref(false);
const newName = ref('');
const qr = ref(null);
const selectedId = ref(null);
const confirmLogout = ref(false);
const busy = ref(false);
let statePoll = null;
let qrRefresh = null;

const selected = computed(() =>
  numbers.value.find(number => number.id === selectedId.value)
);

const load = async () => {
  const data = await fetchNumbers();
  numbers.value = data.payload;
  freelancers.value = data.freelancers;
  loading.value = false;
};

const stopQr = () => {
  clearInterval(statePoll);
  clearInterval(qrRefresh);
  qr.value = null;
};

const showQr = connection => {
  qr.value = { instance: connection.instance, image: connection.qr };
  clearInterval(statePoll);
  clearInterval(qrRefresh);
  statePoll = setInterval(async () => {
    await load();
    const number = numbers.value.find(
      item => item.instance === qr.value?.instance
    );
    if (number?.state !== 'open') return;
    stopQr();
    toast('numbers.connected');
    selectedId.value = number.id;
  }, STATE_POLL);
  qrRefresh = setInterval(async () => {
    const number = numbers.value.find(
      item => item.instance === qr.value?.instance
    );
    if (!number) return;
    const fresh = await connectNumber(number.id);
    if (fresh.qr && qr.value) qr.value.image = fresh.qr;
  }, QR_REFRESH);
};

const run = async action => {
  busy.value = true;
  try {
    await action();
  } catch {
    toast('error.generic');
  } finally {
    busy.value = false;
  }
};

const create = () =>
  run(async () => {
    const connection = await addNumber(newName.value.trim());
    adding.value = false;
    newName.value = '';
    showQr(connection);
  });

const reconnect = number =>
  run(async () => {
    const connection = await connectNumber(number.id);
    selectedId.value = null;
    if (connection.state === 'open') {
      toast('numbers.connected');
      await load();
    } else showQr(connection);
  });

const assign = (number, freelancerId) =>
  run(async () => {
    await assignNumber(number.id, freelancerId);
    await load();
    toast('toast.saved');
  });

const logout = number =>
  run(async () => {
    await logoutNumber(number.id);
    confirmLogout.value = false;
    selectedId.value = null;
    await load();
  });

const closeSelected = () => {
  selectedId.value = null;
  confirmLogout.value = false;
};

onMounted(load);
onBeforeUnmount(stopQr);
</script>

<template>
  <section class="flex h-full w-full flex-col bg-panel">
    <header class="flex h-14 shrink-0 items-center gap-1 px-3">
      <button
        type="button"
        class="grid size-10 place-items-center rounded-full text-muted hover:bg-hover"
        :aria-label="t('nav.back')"
        @click="router.push({ name: 'chats' })"
      >
        <span class="i-lucide-arrow-left size-5" />
      </button>
      <h1 class="flex-1 text-lg font-semibold">{{ t('numbers.title') }}</h1>
      <button
        type="button"
        class="grid size-10 place-items-center rounded-full text-accent hover:bg-hover"
        :aria-label="t('numbers.add')"
        @click="adding = true"
      >
        <span class="i-lucide-plus size-5" />
      </button>
    </header>

    <div class="min-h-0 flex-1 overflow-y-auto">
      <div v-if="loading" class="flex justify-center py-10" aria-busy="true">
        <span class="i-lucide-loader-circle size-6 animate-spin text-faint" />
      </div>
      <div
        v-else-if="!numbers.length"
        class="flex flex-col items-center px-8 py-16 text-center"
      >
        <span class="i-lucide-smartphone mb-3 size-10 text-faint" />
        <p class="font-medium">{{ t('numbers.empty') }}</p>
        <p class="mt-1 text-sm text-muted">{{ t('numbers.empty_text') }}</p>
      </div>
      <button
        v-for="number in numbers"
        :key="number.id"
        type="button"
        class="flex w-full items-center gap-3 px-4 py-3 text-start hover:bg-hover"
        @click="selectedId = number.id"
      >
        <span
          class="grid size-11 shrink-0 place-items-center rounded-full bg-chip text-muted"
        >
          <span class="i-lucide-smartphone size-5" />
        </span>
        <span class="min-w-0 flex-1">
          <span class="block truncate font-medium">{{ number.name }}</span>
          <span class="block truncate text-sm text-muted">
            {{ number.freelancer?.name || t('numbers.no_freelancer') }}
          </span>
        </span>
        <span
          class="shrink-0 rounded-md px-1.5 text-xs leading-5"
          :class="STATE_TONES[number.state] || STATE_TONES.unknown"
        >
          {{ t(`numbers.state.${number.state}`) }}
        </span>
      </button>
    </div>

    <BottomSheet
      v-if="adding"
      :title="t('numbers.add')"
      @close="adding = false"
    >
      <form @submit.prevent="create">
        <label class="mb-2 block">
          <span class="mb-1 block text-sm text-muted">
            {{ t('numbers.name') }}
          </span>
          <input
            v-model="newName"
            type="text"
            required
            class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
            :placeholder="t('numbers.name_placeholder')"
          />
        </label>
        <p class="mb-4 text-xs text-muted">{{ t('numbers.pool_hint') }}</p>
        <button
          type="submit"
          class="h-11 w-full rounded-lg bg-accent font-medium text-on-accent disabled:opacity-50"
          :disabled="busy || !newName.trim()"
        >
          {{ t('numbers.show_qr') }}
        </button>
      </form>
    </BottomSheet>

    <BottomSheet v-if="qr" :title="t('numbers.scan')" @close="stopQr">
      <img
        v-if="qr.image"
        :src="qr.image"
        :alt="t('numbers.scan')"
        class="mx-auto mb-4 size-64 rounded-lg bg-white p-2"
      />
      <ol class="list-decimal space-y-1 ps-5 text-sm text-muted">
        <li>{{ t('numbers.scan_step1') }}</li>
        <li>{{ t('numbers.scan_step2') }}</li>
        <li>{{ t('numbers.scan_step3') }}</li>
      </ol>
      <p class="mt-4 flex items-center gap-2 text-sm text-faint">
        <span class="i-lucide-loader-circle size-4 animate-spin" />
        {{ t('numbers.waiting_scan') }}
      </p>
    </BottomSheet>

    <BottomSheet v-if="selected" :title="selected.name" @close="closeSelected">
      <p class="mb-1 flex items-center gap-2">
        <span
          class="rounded-md px-1.5 text-xs leading-5"
          :class="STATE_TONES[selected.state] || STATE_TONES.unknown"
        >
          {{ t(`numbers.state.${selected.state}`) }}
        </span>
        <span
          v-if="selected.phone_number"
          class="select-all text-sm text-muted"
        >
          {{ selected.phone_number }}
        </span>
      </p>

      <h3 class="mb-2 mt-5 text-sm font-medium text-accent-ink">
        {{ t('numbers.freelancer') }}
      </h3>
      <div class="mb-5 flex flex-wrap gap-2">
        <button
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            selected.freelancer
              ? 'bg-chip text-muted'
              : 'bg-accent text-on-accent'
          "
          :disabled="busy"
          @click="assign(selected, null)"
        >
          {{ t('numbers.no_freelancer') }}
        </button>
        <button
          v-for="freelancer in freelancers"
          :key="freelancer.id"
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            selected.freelancer?.id === freelancer.id
              ? 'bg-accent text-on-accent'
              : 'bg-chip text-muted'
          "
          :disabled="busy"
          @click="assign(selected, freelancer.id)"
        >
          {{ freelancer.name }}
        </button>
      </div>

      <button
        v-if="selected.state !== 'open'"
        type="button"
        class="mb-2 h-11 w-full rounded-lg bg-accent font-medium text-on-accent disabled:opacity-50"
        :disabled="busy"
        @click="reconnect(selected)"
      >
        {{ t('numbers.reconnect') }}
      </button>
      <template v-else>
        <button
          v-if="!confirmLogout"
          type="button"
          class="h-11 w-full rounded-lg bg-chip font-medium text-danger"
          @click="confirmLogout = true"
        >
          {{ t('numbers.logout') }}
        </button>
        <div v-else class="rounded-lg bg-danger-soft p-3">
          <p class="mb-3 text-sm text-danger">
            {{ t('numbers.logout_confirm') }}
          </p>
          <div class="flex gap-2">
            <button
              type="button"
              class="h-10 flex-1 rounded-lg bg-panel text-sm text-muted"
              @click="confirmLogout = false"
            >
              {{ t('composer.cancel') }}
            </button>
            <button
              type="button"
              class="h-10 flex-1 rounded-lg bg-danger text-sm font-medium text-on-accent disabled:opacity-50"
              :disabled="busy"
              @click="logout(selected)"
            >
              {{ t('numbers.logout') }}
            </button>
          </div>
        </div>
      </template>
    </BottomSheet>
  </section>
</template>
