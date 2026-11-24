<script setup>
import { computed, ref } from 'vue';
import BottomSheet from './BottomSheet.vue';
import ChatAvatar from './ChatAvatar.vue';
import { t } from '../lib/i18n';
import { handoff, now, state, toast } from '../lib/store';
import { scheduleLabel } from '../lib/format';

const emit = defineEmits(['close']);

const brief = ref('');
const busy = ref(false);
const freelancer = computed(() => state.chat.header.inbox.freelancer);
const canSubmit = computed(
  () => freelancer.value && brief.value.trim() && !busy.value
);

const submit = async () => {
  if (!canSubmit.value) return;
  busy.value = true;
  try {
    await handoff(brief.value.trim());
    toast('toast.handed_off');
    emit('close');
  } catch {
    toast('error.generic');
  } finally {
    busy.value = false;
  }
};
</script>

<template>
  <BottomSheet :title="t('handoff.title')" @close="emit('close')">
    <h3 class="mb-2 text-sm font-medium text-accent-ink">
      {{ t('handoff.to') }}
    </h3>
    <div
      v-if="freelancer"
      class="mb-5 flex items-center gap-3 rounded-lg bg-chip p-3"
    >
      <ChatAvatar :name="freelancer.name" size="size-10 text-sm" />
      <span class="min-w-0 flex-1">
        <span class="block truncate font-medium">{{ freelancer.name }}</span>
        <span class="block truncate text-xs text-muted">
          {{ state.chat.header.inbox.name }}
          · {{ scheduleLabel(freelancer.schedule, now) }}
        </span>
      </span>
    </div>
    <p v-else class="mb-5 rounded-lg bg-warn-soft p-3 text-sm text-warn">
      {{ t('handoff.no_freelancer') }}
    </p>

    <form @submit.prevent="submit">
      <label class="mb-4 block">
        <span class="mb-1 block text-sm font-medium text-accent-ink">
          {{ t('handoff.brief') }}
        </span>
        <textarea
          v-model="brief"
          rows="5"
          class="w-full resize-y rounded-lg border border-line bg-panel px-3 py-2 outline-none focus:border-accent"
          :placeholder="t('handoff.brief_placeholder')"
        />
      </label>
      <button
        type="submit"
        class="h-11 w-full rounded-lg bg-accent font-medium text-on-accent hover:bg-accent-strong disabled:opacity-50"
        :disabled="!canSubmit"
      >
        {{ t('handoff.submit') }}
      </button>
    </form>
  </BottomSheet>
</template>
