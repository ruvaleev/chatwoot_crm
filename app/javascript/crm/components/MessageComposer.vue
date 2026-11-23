<script setup>
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import BottomSheet from './BottomSheet.vue';
import { t } from '../lib/i18n';
import { fetchTemplates, sendMessage, toast } from '../lib/store';
import { fileSize, matchTemplates, voiceFileName } from '../lib/format';

const text = ref('');
const isNote = ref(false);
const attachOpen = ref(false);
const pending = ref([]);
const caption = ref('');
const photoInput = ref(null);
const fileInput = ref(null);
const recording = ref(null);
const seconds = ref(0);
let recorder = null;
let chunks = [];
let timer = null;

const canSend = computed(() => text.value.trim().length > 0);
const templates = ref(null);
const templateQuery = computed(() =>
  text.value.startsWith('/') ? text.value.slice(1) : null
);
const suggestions = computed(() =>
  templateQuery.value === null
    ? []
    : matchTemplates(templates.value || [], templateQuery.value)
);

watch(templateQuery, async query => {
  if (query === null || templates.value) return;
  templates.value = await fetchTemplates().catch(() => []);
});

const useTemplate = template => {
  text.value = template.content;
};
const timerLabel = computed(
  () =>
    `${Math.floor(seconds.value / 60)}:${String(seconds.value % 60).padStart(2, '0')}`
);

const sendText = () => {
  if (!canSend.value) return;
  sendMessage({ content: text.value.trim(), isPrivate: isNote.value });
  text.value = '';
};

const onKeydown = event => {
  if (event.key !== 'Enter' || event.shiftKey || event.isComposing) return;
  event.preventDefault();
  if (templateQuery.value !== null && suggestions.value.length) {
    useTemplate(suggestions.value[0]);
    return;
  }
  sendText();
};

const pick = input => {
  attachOpen.value = false;
  input.value.click();
};

const onFiles = event => {
  pending.value = [...event.target.files].map(file => ({
    file,
    url: file.type.startsWith('image/') ? URL.createObjectURL(file) : null,
  }));
  caption.value = text.value;
  event.target.value = '';
};

const closePreview = () => {
  pending.value.forEach(item => item.url && URL.revokeObjectURL(item.url));
  pending.value = [];
};

const sendFiles = () => {
  sendMessage({
    content: caption.value.trim(),
    isPrivate: isNote.value,
    files: pending.value.map(item => item.file),
  });
  text.value = '';
  closePreview();
};

const startRecording = async () => {
  let stream;
  try {
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  } catch {
    toast('composer.mic_denied');
    return;
  }
  chunks = [];
  recorder = new MediaRecorder(stream);
  recorder.ondataavailable = event => chunks.push(event.data);
  recorder.start();
  recording.value = { stream };
  seconds.value = 0;
  timer = setInterval(() => {
    seconds.value += 1;
  }, 1000);
};

const stopRecording = send => {
  clearInterval(timer);
  if (!recorder) return;
  recorder.onstop = () => {
    recording.value?.stream.getTracks().forEach(track => track.stop());
    recording.value = null;
    if (!send || !chunks.length) return;
    const blob = new Blob(chunks, { type: recorder.mimeType });
    const name = voiceFileName(recorder.mimeType);
    sendMessage({
      isPrivate: isNote.value,
      files: [new File([blob], name, { type: blob.type })],
    });
  };
  recorder.stop();
};

onBeforeUnmount(() => {
  if (recording.value) stopRecording(false);
});
</script>

<template>
  <footer
    class="shrink-0 bg-head px-2 pb-[calc(0.5rem+env(safe-area-inset-bottom))] pt-1.5"
  >
    <div class="mb-1.5 flex gap-1.5 px-1">
      <button
        type="button"
        :aria-pressed="!isNote"
        class="h-7 rounded-full px-3 text-xs"
        :class="!isNote ? 'bg-panel text-ink shadow-sm' : 'text-muted'"
        @click="isNote = false"
      >
        {{ t('composer.to_client') }}
      </button>
      <button
        type="button"
        :aria-pressed="isNote"
        class="flex h-7 items-center gap-1 rounded-full px-3 text-xs"
        :class="isNote ? 'bg-note text-note-ink shadow-sm' : 'text-muted'"
        @click="isNote = true"
      >
        <span class="i-lucide-lock size-3" />{{ t('composer.to_note') }}
      </button>
    </div>

    <div v-if="recording" class="flex items-center gap-2">
      <button
        type="button"
        class="grid size-11 place-items-center rounded-full text-danger hover:bg-hover"
        :aria-label="t('composer.cancel')"
        @click="stopRecording(false)"
      >
        <span class="i-lucide-trash-2 size-5" />
      </button>
      <div
        class="flex h-11 flex-1 items-center gap-2 rounded-full bg-panel px-4"
      >
        <span class="size-2.5 animate-pulse rounded-full bg-danger" />
        <span class="text-sm text-muted">
          {{ t('composer.recording') }} {{ timerLabel }}
        </span>
      </div>
      <button
        type="button"
        class="grid size-11 place-items-center rounded-full bg-accent text-on-accent"
        :aria-label="t('composer.send')"
        @click="stopRecording(true)"
      >
        <span class="i-lucide-send-horizontal size-5" />
      </button>
    </div>

    <div v-else class="flex items-end gap-2">
      <div
        class="relative flex min-h-11 flex-1 items-end rounded-3xl px-1"
        :class="isNote ? 'bg-note' : 'bg-panel'"
      >
        <ul
          v-if="templateQuery !== null && templates"
          class="absolute inset-x-0 bottom-12 z-30 max-h-64 overflow-y-auto rounded-xl bg-panel py-1 shadow-pop"
        >
          <li v-if="!suggestions.length" class="px-4 py-2.5 text-sm text-muted">
            {{ t('templates.empty') }}
          </li>
          <li v-for="template in suggestions" :key="template.id">
            <button
              type="button"
              class="block w-full px-4 py-2 text-start hover:bg-hover"
              @click="useTemplate(template)"
            >
              <span class="block text-xs font-medium text-accent-ink">
                /{{ template.short_code }}
              </span>
              <span class="block truncate text-sm">
                {{ template.content }}
              </span>
            </button>
          </li>
        </ul>
        <button
          type="button"
          class="grid size-10 shrink-0 place-items-center rounded-full text-muted hover:bg-hover"
          :aria-label="t('composer.attach')"
          :aria-expanded="attachOpen"
          @click="attachOpen = !attachOpen"
        >
          <span class="i-lucide-paperclip size-5" />
        </button>
        <div
          v-if="attachOpen"
          class="fixed inset-0 z-20"
          @click="attachOpen = false"
        />
        <div
          v-if="attachOpen"
          class="absolute bottom-12 start-0 z-30 w-56 overflow-hidden rounded-xl bg-panel py-1 shadow-pop"
        >
          <button
            type="button"
            class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
            @click="pick(photoInput)"
          >
            <span class="i-lucide-image size-5 text-accent" />{{
              t('composer.photo')
            }}
          </button>
          <button
            type="button"
            class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
            @click="pick(fileInput)"
          >
            <span class="i-lucide-file-text size-5 text-accent" />{{
              t('composer.document')
            }}
          </button>
        </div>
        <textarea
          v-model="text"
          rows="1"
          class="max-h-40 min-h-10 flex-1 resize-none bg-transparent px-1 py-2.5 outline-none [field-sizing:content] placeholder:text-faint"
          :placeholder="
            isNote ? t('composer.note_placeholder') : t('composer.placeholder')
          "
          :aria-label="t('composer.placeholder')"
          @keydown="onKeydown"
        />
      </div>
      <button
        v-if="canSend"
        type="button"
        class="grid size-11 shrink-0 place-items-center rounded-full bg-accent text-on-accent hover:bg-accent-strong"
        :aria-label="t('composer.send')"
        @click="sendText"
      >
        <span class="i-lucide-send-horizontal size-5" />
      </button>
      <button
        v-else
        type="button"
        class="grid size-11 shrink-0 place-items-center rounded-full bg-accent text-on-accent hover:bg-accent-strong"
        :aria-label="t('composer.record')"
        @click="startRecording"
      >
        <span class="i-lucide-mic size-5" />
      </button>
    </div>

    <input
      ref="photoInput"
      type="file"
      accept="image/*,video/*"
      multiple
      class="hidden"
      @change="onFiles"
    />
    <input
      ref="fileInput"
      type="file"
      multiple
      class="hidden"
      @change="onFiles"
    />

    <BottomSheet
      v-if="pending.length"
      :title="t('composer.send')"
      @close="closePreview"
    >
      <ul class="mb-3 space-y-2">
        <li
          v-for="(item, index) in pending"
          :key="index"
          class="flex items-center gap-3 rounded-lg bg-chip p-2"
        >
          <img
            v-if="item.url"
            :src="item.url"
            alt=""
            class="size-16 rounded-md object-cover"
          />
          <span
            v-else
            class="i-lucide-file-text size-10 shrink-0 text-accent"
          />
          <span class="min-w-0 flex-1">
            <span class="block truncate text-sm">{{ item.file.name }}</span>
            <span class="text-xs text-faint">{{
              fileSize(item.file.size)
            }}</span>
          </span>
        </li>
      </ul>
      <div class="flex items-end gap-2">
        <input
          v-model="caption"
          type="text"
          class="h-11 flex-1 rounded-full bg-chip px-4 outline-none placeholder:text-faint"
          :placeholder="t('composer.caption')"
          :aria-label="t('composer.caption')"
          @keydown.enter.prevent="sendFiles"
        />
        <button
          type="button"
          class="grid size-11 place-items-center rounded-full bg-accent text-on-accent"
          :aria-label="t('composer.send')"
          @click="sendFiles"
        >
          <span class="i-lucide-send-horizontal size-5" />
        </button>
      </div>
    </BottomSheet>
  </footer>
</template>
