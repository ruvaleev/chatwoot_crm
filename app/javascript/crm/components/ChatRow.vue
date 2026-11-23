<script setup>
import { computed } from 'vue';
import ChatAvatar from './ChatAvatar.vue';
import StatusTag from './StatusTag.vue';
import MessageTicks from './MessageTicks.vue';
import { t } from '../lib/i18n';
import { now } from '../lib/store';
import {
  isOverdue,
  listTime,
  previewText,
  waitingLabel,
  waitingMinutes,
} from '../lib/format';

const props = defineProps({
  chat: { type: Object, required: true },
  active: { type: Boolean, default: false },
});
const emit = defineEmits(['open', 'menu']);

const LONG_PRESS = 500;
const overdue = computed(() => isOverdue(props.chat, now.value));
const last = computed(() => props.chat.last_message);
let pressTimer = null;
let pressed = false;

const startPress = () => {
  pressed = false;
  pressTimer = setTimeout(() => {
    pressed = true;
    emit('menu', props.chat);
  }, LONG_PRESS);
};
const endPress = () => clearTimeout(pressTimer);
const open = () => {
  if (!pressed) emit('open', props.chat);
};
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group relative flex cursor-pointer select-none gap-3 px-3 py-2.5"
    :class="active ? 'bg-active' : 'hover:bg-hover'"
    @click="open"
    @keydown.enter="open"
    @contextmenu.prevent="emit('menu', chat)"
    @pointerdown="startPress"
    @pointerup="endPress"
    @pointerleave="endPress"
  >
    <span
      v-if="overdue"
      class="absolute inset-y-2 start-0 w-1 rounded-e bg-danger"
    />
    <ChatAvatar :name="chat.contact.name" />
    <div class="min-w-0 flex-1 border-b border-line pb-2.5">
      <div class="flex items-baseline gap-2">
        <span class="flex-1 truncate font-medium">{{ chat.contact.name }}</span>
        <span
          class="shrink-0 text-xs"
          :class="
            overdue
              ? 'text-danger'
              : chat.unread_count
                ? 'text-accent'
                : 'text-faint'
          "
        >
          {{ listTime(last?.created_at || chat.last_activity_at) }}
        </span>
      </div>
      <div class="mt-0.5 flex items-center gap-1.5">
        <MessageTicks v-if="last && !last.incoming" :status="last.status" />
        <span
          v-if="last?.attachment_type && !last.content"
          class="i-lucide-paperclip size-3.5 shrink-0 text-faint"
        />
        <span class="flex-1 truncate text-sm text-muted">{{
          previewText(last)
        }}</span>
        <span
          v-if="chat.unread_count"
          class="grid h-5 min-w-5 shrink-0 place-items-center rounded-full bg-accent px-1.5 text-xs font-semibold text-on-accent"
        >
          {{ chat.unread_count }}
        </span>
      </div>
      <div class="mt-1 flex flex-wrap items-center gap-1.5">
        <span
          v-if="chat.status === 'handed_off'"
          class="rounded-md bg-accent-soft px-1.5 text-xs leading-5 text-accent-ink"
        >
          {{ t('row.fresh') }}
        </span>
        <span
          v-if="overdue"
          class="inline-flex items-center gap-1 rounded-md bg-danger-soft px-1.5 text-xs font-semibold leading-5 text-danger"
        >
          <span class="i-lucide-clock size-3" />
          {{ waitingLabel(waitingMinutes(chat.waiting_since, now)) }}
        </span>
        <StatusTag v-if="chat.status !== 'handed_off'" :status="chat.status" />
        <span
          v-for="label in chat.contact.labels"
          :key="label"
          class="rounded-md border border-line px-1.5 text-xs leading-5 text-muted"
        >
          {{ label }}
        </span>
      </div>
    </div>
  </div>
</template>
