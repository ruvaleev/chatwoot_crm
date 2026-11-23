<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useRouter } from 'vue-router';
import BottomSheet from './BottomSheet.vue';
import ChatAvatar from './ChatAvatar.vue';
import { t } from '../lib/i18n';
import {
  addFreelancer,
  fetchFreelancers,
  inviteFreelancer,
  moveFreelancer,
  removeFreelancer,
  toast,
} from '../lib/store';

const router = useRouter();

const freelancers = ref([]);
const numbers = ref([]);
const loading = ref(true);
const adding = ref(false);
const form = reactive({ name: '', login: '', numberId: null });
const inviteUrl = ref(null);
const selectedId = ref(null);
const confirmRemove = ref(false);
const busy = ref(false);
const error = ref('');

const selected = computed(() =>
  freelancers.value.find(freelancer => freelancer.id === selectedId.value)
);

const load = async () => {
  const data = await fetchFreelancers();
  freelancers.value = data.payload;
  numbers.value = data.numbers;
  loading.value = false;
};

const run = async action => {
  busy.value = true;
  error.value = '';
  try {
    await action();
  } catch (failure) {
    if (failure.status === 422) error.value = failure.message;
    else toast('error.generic');
  } finally {
    busy.value = false;
  }
};

const create = () =>
  run(async () => {
    const created = await addFreelancer({
      name: form.name.trim(),
      login: form.login.trim(),
      number_id: form.numberId,
    });
    Object.assign(form, { name: '', login: '', numberId: null });
    adding.value = false;
    inviteUrl.value = created.invite_url;
    await load();
  });

const move = (freelancer, numberId) =>
  run(async () => {
    await moveFreelancer(freelancer.id, numberId);
    await load();
    toast('toast.saved');
  });

const reinvite = freelancer =>
  run(async () => {
    const { invite_url: url } = await inviteFreelancer(freelancer.id);
    selectedId.value = null;
    inviteUrl.value = url;
  });

const remove = freelancer =>
  run(async () => {
    await removeFreelancer(freelancer.id);
    selectedId.value = null;
    confirmRemove.value = false;
    await load();
  });

const copy = async () => {
  await navigator.clipboard.writeText(inviteUrl.value);
  toast('freelancers.copied');
};

const closeSelected = () => {
  selectedId.value = null;
  confirmRemove.value = false;
};

onMounted(load);
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
      <h1 class="flex-1 text-lg font-semibold">
        {{ t('freelancers.title') }}
      </h1>
      <button
        type="button"
        class="grid size-10 place-items-center rounded-full text-accent hover:bg-hover"
        :aria-label="t('freelancers.add')"
        @click="adding = true"
      >
        <span class="i-lucide-user-plus size-5" />
      </button>
    </header>

    <div class="min-h-0 flex-1 overflow-y-auto">
      <div v-if="loading" class="flex justify-center py-10" aria-busy="true">
        <span class="i-lucide-loader-circle size-6 animate-spin text-faint" />
      </div>
      <div
        v-else-if="!freelancers.length"
        class="flex flex-col items-center px-8 py-16 text-center"
      >
        <span class="i-lucide-users mb-3 size-10 text-faint" />
        <p class="font-medium">{{ t('freelancers.empty') }}</p>
        <p class="mt-1 text-sm text-muted">
          {{ t('freelancers.empty_text') }}
        </p>
      </div>
      <button
        v-for="freelancer in freelancers"
        :key="freelancer.id"
        type="button"
        class="flex w-full items-center gap-3 px-4 py-3 text-start hover:bg-hover"
        @click="selectedId = freelancer.id"
      >
        <ChatAvatar :name="freelancer.name" size="size-11 text-sm" />
        <span class="min-w-0 flex-1">
          <span class="block truncate font-medium">{{ freelancer.name }}</span>
          <span class="block truncate text-sm text-muted">
            {{
              t('freelancers.row', {
                number: freelancer.number?.name || t('freelancers.no_number'),
                n: freelancer.clients_count,
              })
            }}
          </span>
        </span>
        <span
          v-if="freelancer.invited"
          class="shrink-0 rounded-md bg-warn-soft px-1.5 text-xs leading-5 text-warn"
        >
          {{ t('freelancers.invited') }}
        </span>
      </button>
    </div>

    <BottomSheet
      v-if="adding"
      :title="t('freelancers.add')"
      @close="adding = false"
    >
      <form @submit.prevent="create">
        <label class="mb-3 block">
          <span class="mb-1 block text-sm text-muted">
            {{ t('freelancers.name') }}
          </span>
          <input
            v-model="form.name"
            type="text"
            required
            class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
          />
        </label>
        <label class="mb-1 block">
          <span class="mb-1 block text-sm text-muted">
            {{ t('freelancers.login') }}
          </span>
          <input
            v-model="form.login"
            type="text"
            required
            autocapitalize="none"
            class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
            :placeholder="t('freelancers.login_placeholder')"
          />
        </label>
        <p class="mb-4 text-xs text-faint">{{ t('freelancers.login_hint') }}</p>
        <h3 class="mb-2 text-sm font-medium text-accent-ink">
          {{ t('numbers.title') }}
        </h3>
        <div class="mb-5 flex flex-wrap gap-2">
          <button
            v-for="number in numbers"
            :key="number.id"
            type="button"
            class="h-8 rounded-full px-3 text-sm"
            :class="
              form.numberId === number.id
                ? 'bg-accent text-on-accent'
                : 'bg-chip text-muted'
            "
            @click="
              form.numberId = form.numberId === number.id ? null : number.id
            "
          >
            {{ number.name }}
          </button>
        </div>
        <p
          v-if="error"
          class="mb-4 rounded-lg bg-danger-soft px-3 py-2 text-sm text-danger"
        >
          {{ error }}
        </p>
        <button
          type="submit"
          class="h-11 w-full rounded-lg bg-accent font-medium text-on-accent disabled:opacity-50"
          :disabled="busy || !form.name.trim() || !form.login.trim()"
        >
          {{ t('freelancers.create') }}
        </button>
      </form>
    </BottomSheet>

    <BottomSheet
      v-if="inviteUrl"
      :title="t('freelancers.link_title')"
      @close="inviteUrl = null"
    >
      <p class="mb-3 text-sm text-muted">{{ t('freelancers.link_text') }}</p>
      <p class="mb-4 select-all break-all rounded-lg bg-chip p-3 text-sm">
        {{ inviteUrl }}
      </p>
      <button
        type="button"
        class="h-11 w-full rounded-lg bg-accent font-medium text-on-accent"
        @click="copy"
      >
        {{ t('freelancers.copy') }}
      </button>
    </BottomSheet>

    <BottomSheet v-if="selected" :title="selected.name" @close="closeSelected">
      <p class="mb-5 text-sm text-muted">
        {{ t('freelancers.login') }}: {{ selected.login }}
      </p>
      <h3 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('numbers.title') }}
      </h3>
      <div class="mb-5 flex flex-wrap gap-2">
        <button
          v-for="number in numbers"
          :key="number.id"
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            selected.number?.id === number.id
              ? 'bg-accent text-on-accent'
              : 'bg-chip text-muted'
          "
          :disabled="busy"
          @click="move(selected, number.id)"
        >
          {{ number.name }}
        </button>
      </div>
      <button
        type="button"
        class="mb-2 h-11 w-full rounded-lg bg-chip font-medium text-ink disabled:opacity-50"
        :disabled="busy"
        @click="reinvite(selected)"
      >
        {{ t('freelancers.new_link') }}
      </button>
      <button
        v-if="!confirmRemove"
        type="button"
        class="h-11 w-full rounded-lg bg-chip font-medium text-danger"
        @click="confirmRemove = true"
      >
        {{ t('freelancers.remove') }}
      </button>
      <div v-else class="rounded-lg bg-danger-soft p-3">
        <p class="mb-3 text-sm text-danger">
          {{ t('freelancers.remove_confirm') }}
        </p>
        <div class="flex gap-2">
          <button
            type="button"
            class="h-10 flex-1 rounded-lg bg-panel text-sm text-muted"
            @click="confirmRemove = false"
          >
            {{ t('composer.cancel') }}
          </button>
          <button
            type="button"
            class="h-10 flex-1 rounded-lg bg-danger text-sm font-medium text-on-accent disabled:opacity-50"
            :disabled="busy"
            @click="remove(selected)"
          >
            {{ t('freelancers.remove') }}
          </button>
        </div>
      </div>
    </BottomSheet>
  </section>
</template>
