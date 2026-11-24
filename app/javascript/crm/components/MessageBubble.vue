<script setup>
import { computed } from 'vue';
import MessageTicks from './MessageTicks.vue';
import { t } from '../lib/i18n';
import { clock, fileSize, MESSAGE_TYPE } from '../lib/format';

const props = defineProps({
  message: { type: Object, required: true },
  currentUserId: { type: Number, required: true },
});
const emit = defineEmits(['retry']);

const incoming = computed(
  () => props.message.message_type === MESSAGE_TYPE.incoming
);
// Teammates' messages from the same number are signed for the team; the client sees one person.
const author = computed(() => {
  const { sender } = props.message;
  if (incoming.value || !sender || sender.id === props.currentUserId) return '';
  return sender.available_name || sender.name || '';
});
const bubbleClass = computed(() => {
  if (props.message.private)
    return 'self-end border border-dashed border-note-line bg-note';
  return incoming.value ? 'self-start bg-bubble-in' : 'self-end bg-bubble-out';
});
</script>

<template>
  <div
    class="relative max-w-[85%] rounded-lg px-2 pb-1 pt-1.5 shadow-sm md:max-w-[65%]"
    :class="[bubbleClass]"
  >
    <p
      v-if="message.private"
      class="mb-1 flex items-center gap-1 text-xs font-medium text-note-ink"
    >
      <span class="i-lucide-lock size-3" />{{ t('chat.note') }}
    </p>
    <p v-if="author" class="mb-0.5 text-xs font-medium text-accent-ink">
      {{ author }}
    </p>

    <div
      v-for="(file, index) in message.attachments || []"
      :key="index"
      class="mb-1"
    >
      <a
        v-if="file.file_type === 'image'"
        :href="file.data_url"
        target="_blank"
        rel="noopener noreferrer"
      >
        <img
          :src="file.thumb_url || file.data_url"
          alt=""
          class="max-h-72 w-full rounded-md object-cover"
          loading="lazy"
        />
      </a>
      <video
        v-else-if="file.file_type === 'video'"
        :src="file.data_url"
        controls
        preload="metadata"
        class="max-h-72 w-full rounded-md"
      />
      <audio
        v-else-if="file.file_type === 'audio'"
        :src="file.data_url"
        controls
        preload="metadata"
        class="w-64 max-w-full"
      />
      <a
        v-else
        :href="file.data_url"
        target="_blank"
        rel="noopener noreferrer"
        class="flex items-center gap-3 rounded-md bg-black/5 px-3 py-2"
      >
        <span class="i-lucide-file-text size-8 shrink-0 text-accent" />
        <span class="min-w-0">
          <span class="block truncate text-sm">{{
            file.fallback_title ||
            file.extension?.toUpperCase() ||
            t('preview.file')
          }}</span>
          <span class="text-xs text-faint">{{ fileSize(file.file_size) }}</span>
        </span>
      </a>
    </div>

    <p v-if="message.content" class="whitespace-pre-wrap break-words pe-14">
      {{ message.content }}
    </p>
    <span
      class="flex items-center gap-1 text-[11px] text-faint"
      :class="[message.content ? 'float-end -mt-3.5 ms-2' : 'justify-end']"
    >
      {{ clock(message.created_at) }}
      <MessageTicks v-if="!incoming" :status="message.status" />
    </span>
    <span class="block clear-both" />

    <button
      v-if="message.status === 'failed'"
      type="button"
      class="mt-1 flex items-center gap-1 text-xs font-medium text-danger"
      @click="emit('retry', message)"
    >
      <span class="i-lucide-rotate-cw size-3.5" />{{ t('chat.failed_retry') }}
    </button>
  </div>
</template>
