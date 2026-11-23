<script setup>
import { computed, nextTick, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import ChatAvatar from './ChatAvatar.vue';
import MessageBubble from './MessageBubble.vue';
import MessageComposer from './MessageComposer.vue';
import ClientSheet from './ClientSheet.vue';
import { t } from '../lib/i18n';
import {
  loadOlder,
  openChat,
  retryMessage,
  setHidden,
  state,
} from '../lib/store';
import { dayLabel, MESSAGE_TYPE, sameDay } from '../lib/format';

const props = defineProps({ id: { type: Number, required: true } });
const router = useRouter();

const scroller = ref(null);
const menuOpen = ref(false);
const sheet = ref(null);
const briefOpen = ref(false);

const chat = computed(() => state.chat);
const header = computed(() => chat.value.header);
const messages = computed(() =>
  chat.value.messages.filter(
    message => message.message_type !== MESSAGE_TYPE.activity || message.content
  )
);

const nearBottom = () => {
  const el = scroller.value;
  return !el || el.scrollHeight - el.scrollTop - el.clientHeight < 120;
};
const scrollToBottom = async () => {
  await nextTick();
  if (scroller.value) scroller.value.scrollTop = scroller.value.scrollHeight;
};

watch(
  () => props.id,
  async id => {
    briefOpen.value = false;
    await openChat(id);
    scrollToBottom();
  },
  { immediate: true }
);

watch(
  () => chat.value.messages.length,
  (length, previous) => {
    if (length > previous && nearBottom()) scrollToBottom();
  }
);

const showOlder = async () => {
  const el = scroller.value;
  const before = el.scrollHeight;
  await loadOlder();
  await nextTick();
  el.scrollTop = el.scrollHeight - before;
};

const openSheet = section => {
  menuOpen.value = false;
  sheet.value = section;
};
const toggleHidden = () => {
  menuOpen.value = false;
  setHidden(props.id, !header.value.hidden);
};
const showDay = index =>
  index === 0 ||
  !sameDay(
    messages.value[index - 1].created_at,
    messages.value[index].created_at
  );
</script>

<template>
  <section class="flex h-full min-w-0 flex-1 flex-col bg-wall">
    <header class="flex h-14 shrink-0 items-center gap-1 bg-head px-2">
      <button
        type="button"
        class="grid size-10 place-items-center rounded-full text-muted hover:bg-hover md:hidden"
        :aria-label="t('nav.back')"
        @click="router.push({ name: 'chats' })"
      >
        <span class="i-lucide-arrow-left size-5" />
      </button>
      <button
        v-if="header"
        type="button"
        class="flex min-w-0 flex-1 items-center gap-3 rounded-lg px-1 py-1 text-start"
        :aria-label="t('menu.profile')"
        @click="openSheet('profile')"
      >
        <ChatAvatar :name="header.contact.name" size="size-10 text-sm" />
        <span class="min-w-0">
          <span class="block truncate font-medium">{{
            header.contact.name
          }}</span>
          <span class="block truncate text-xs text-muted">{{
            t(`status.${header.status}`)
          }}</span>
        </span>
      </button>
      <div v-else class="flex-1" />
      <div v-if="header" class="relative">
        <button
          type="button"
          class="grid size-10 place-items-center rounded-full text-muted hover:bg-hover"
          :aria-label="t('nav.more')"
          :aria-expanded="menuOpen"
          @click="menuOpen = !menuOpen"
        >
          <span class="i-lucide-ellipsis-vertical size-5" />
        </button>
        <div
          v-if="menuOpen"
          class="fixed inset-0 z-20"
          @click="menuOpen = false"
        />
        <div
          v-if="menuOpen"
          class="absolute end-0 top-11 z-30 w-56 overflow-hidden rounded-xl bg-panel py-1 shadow-pop"
        >
          <button
            type="button"
            class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
            @click="openSheet('profile')"
          >
            <span class="i-lucide-user size-5 text-muted" />{{
              t('menu.profile')
            }}
          </button>
          <button
            type="button"
            class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
            @click="openSheet('labels')"
          >
            <span class="i-lucide-tag size-5 text-muted" />{{
              t('menu.labels')
            }}
          </button>
          <button
            type="button"
            class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
            @click="toggleHidden"
          >
            <span
              class="size-5 text-muted"
              :class="
                header.hidden ? 'i-lucide-archive-restore' : 'i-lucide-archive'
              "
            />
            {{ header.hidden ? t('menu.unhide') : t('menu.hide') }}
          </button>
        </div>
      </div>
    </header>

    <button
      v-if="header?.brief"
      type="button"
      class="flex shrink-0 items-start gap-3 border-b border-line bg-panel px-4 py-2 text-start"
      :aria-expanded="briefOpen"
      @click="briefOpen = !briefOpen"
    >
      <span class="i-lucide-pin mt-0.5 size-4 shrink-0 text-accent" />
      <span class="min-w-0 flex-1">
        <span class="block text-xs font-medium text-accent-ink">{{
          t('chat.brief_by', { name: header.brief.author })
        }}</span>
        <span
          class="block text-sm text-muted"
          :class="briefOpen ? 'whitespace-pre-wrap' : 'truncate'"
        >
          {{ header.brief.content }}
        </span>
      </span>
      <span
        class="mt-0.5 size-4 shrink-0 text-faint"
        :class="briefOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
      />
    </button>

    <div
      ref="scroller"
      class="min-h-0 flex-1 overflow-y-auto px-3 py-3 md:px-12"
    >
      <div
        v-if="chat.loading && !messages.length"
        class="flex justify-center py-10"
        aria-busy="true"
      >
        <span class="i-lucide-loader-circle size-6 animate-spin text-faint" />
      </div>
      <div v-else class="flex flex-col gap-1">
        <button
          v-if="chat.hasOlder && messages.length >= 20"
          type="button"
          class="mx-auto mb-2 rounded-full bg-panel px-3 py-1 text-xs text-muted shadow-sm"
          @click="showOlder"
        >
          {{ t('chat.load_older') }}
        </button>
        <p
          v-if="!messages.length"
          class="mx-auto rounded-lg bg-panel px-3 py-1.5 text-xs text-muted"
        >
          {{ t('chat.empty') }}
        </p>
        <template v-for="(message, index) in messages" :key="message.id">
          <p
            v-if="showDay(index)"
            class="mx-auto my-2 rounded-lg bg-panel px-3 py-1 text-xs text-muted shadow-sm"
          >
            {{ dayLabel(message.created_at) }}
          </p>
          <p
            v-if="message.message_type === MESSAGE_TYPE.activity"
            class="mx-auto my-1 max-w-[85%] rounded-lg bg-panel/80 px-3 py-1 text-center text-xs text-muted"
          >
            {{ message.content }}
          </p>
          <MessageBubble
            v-else
            :message="message"
            :current-user-id="state.user.id"
            @retry="retryMessage"
          />
        </template>
      </div>
    </div>

    <MessageComposer v-if="header" />
    <ClientSheet
      v-if="sheet && header"
      :section="sheet"
      @close="sheet = null"
    />
  </section>
</template>
