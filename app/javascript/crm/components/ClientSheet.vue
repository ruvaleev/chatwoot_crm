<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import BottomSheet from './BottomSheet.vue';
import ChatAvatar from './ChatAvatar.vue';
import { t } from '../lib/i18n';
import {
  fetchLabels,
  renameContact,
  setContactLabels,
  state,
  toast,
  updateDeal,
} from '../lib/store';

const props = defineProps({ section: { type: String, default: 'profile' } });
const emit = defineEmits(['close']);

const ALL_STATUSES = [
  'new',
  'qualifying',
  'handed_off',
  'in_work',
  'won',
  'lost',
  'spam',
];
const FREELANCER_STATUSES = ['in_work', 'won', 'lost', 'spam'];
const DEAL_FIELDS = ['budget', 'deal_amount', 'lost_reason'];

const header = computed(() => state.chat.header);
const isFreelancer = computed(
  () => state.user?.custom_attributes?.crm_freelancer === true
);
const statuses = computed(() =>
  isFreelancer.value ? FREELANCER_STATUSES : ALL_STATUSES
);
const name = ref(header.value.contact.name);
const deal = reactive({ ...header.value.deal });
const accountLabels = ref([]);
const title = computed(() =>
  t(props.section === 'labels' ? 'labels.title' : 'profile.title')
);

onMounted(async () => {
  accountLabels.value = await fetchLabels();
});

const run = async (action, savedToast = 'toast.saved') => {
  try {
    await action();
    if (savedToast) toast(savedToast);
  } catch {
    toast('error.generic');
  }
};

const saveName = () => run(() => renameContact(name.value.trim()));
const setStatus = status =>
  run(() => updateDeal(state.chat.id, { status }), null);
const saveDeal = () => run(() => updateDeal(state.chat.id, { ...deal }));
const toggleLabel = label => {
  const current = header.value.contact.labels;
  const next = current.includes(label)
    ? current.filter(item => item !== label)
    : [...current, label];
  run(() => setContactLabels(next), null);
};
</script>

<template>
  <BottomSheet :title="title" @close="emit('close')">
    <template v-if="section === 'profile'">
      <div class="mb-4 flex flex-col items-center gap-2">
        <ChatAvatar :name="header.contact.name" size="size-20 text-2xl" />
      </div>
      <form class="mb-5 flex gap-2" @submit.prevent="saveName">
        <label class="flex-1">
          <span class="mb-1 block text-xs text-muted">{{
            t('profile.name')
          }}</span>
          <input
            v-model="name"
            type="text"
            class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
            :placeholder="t('profile.name_placeholder')"
          />
        </label>
        <button
          type="submit"
          class="mt-5 h-10 rounded-lg bg-accent px-4 text-sm font-medium text-on-accent"
        >
          {{ t('profile.save') }}
        </button>
      </form>

      <div v-if="header.phone_number" class="mb-5">
        <span class="mb-1 block text-xs text-muted">{{
          t('profile.phone')
        }}</span>
        <p class="select-all font-medium">{{ header.phone_number }}</p>
      </div>

      <h3 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('menu.status') }}
      </h3>
      <div class="mb-5 flex flex-wrap gap-2">
        <button
          v-for="status in statuses"
          :key="status"
          type="button"
          :aria-pressed="header.status === status"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            header.status === status
              ? 'bg-accent text-on-accent'
              : 'bg-chip text-muted'
          "
          @click="setStatus(status)"
        >
          {{ t(`status.${status}`) }}
        </button>
      </div>

      <h3 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('profile.deal') }}
      </h3>
      <form class="mb-5 space-y-2" @submit.prevent="saveDeal">
        <label v-for="field in DEAL_FIELDS" :key="field" class="block">
          <span class="mb-1 block text-xs text-muted">{{
            t(`deal.${field}`)
          }}</span>
          <input
            v-model="deal[field]"
            type="text"
            class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
          />
        </label>
        <button
          type="submit"
          class="h-10 w-full rounded-lg bg-accent text-sm font-medium text-on-accent"
        >
          {{ t('profile.save') }}
        </button>
      </form>

      <template v-if="header.brief">
        <h3 class="mb-2 text-sm font-medium text-accent-ink">
          {{ t('chat.brief_by', { name: header.brief.author }) }}
        </h3>
        <p class="mb-5 whitespace-pre-wrap rounded-lg bg-note p-3 text-sm">
          {{ header.brief.content }}
        </p>
      </template>
    </template>

    <h3
      v-if="section === 'profile'"
      class="mb-2 text-sm font-medium text-accent-ink"
    >
      {{ t('labels.title') }}
    </h3>
    <p v-if="!accountLabels.length" class="text-sm text-muted">
      {{ t('labels.empty') }}
    </p>
    <div class="flex flex-wrap gap-2">
      <button
        v-for="label in accountLabels"
        :key="label"
        type="button"
        :aria-pressed="header.contact.labels.includes(label)"
        class="h-8 rounded-full border px-3 text-sm"
        :class="
          header.contact.labels.includes(label)
            ? 'border-accent bg-accent-soft text-accent-ink'
            : 'border-line text-muted'
        "
        @click="toggleLabel(label)"
      >
        {{ label }}
      </button>
    </div>
  </BottomSheet>
</template>
