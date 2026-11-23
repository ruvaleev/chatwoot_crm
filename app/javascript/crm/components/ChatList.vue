<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import ChatRow from './ChatRow.vue';
import BottomSheet from './BottomSheet.vue';
import { t } from '../lib/i18n';
import { loadList, loadMore, setHidden, state } from '../lib/store';
import { previewText } from '../lib/format';

const props = defineProps({
  hiddenView: { type: Boolean, default: false },
  activeId: { type: Number, default: null },
});
const router = useRouter();

const tab = ref('waiting');
const query = ref('');
const menuOpen = ref(false);
const rowMenu = ref(null);
const sentinel = ref(null);
let observer = null;

const filter = computed(() => (props.hiddenView ? 'hidden' : tab.value));
const list = computed(() => state.list);
const rows = computed(() => {
  const needle = query.value.trim().toLowerCase();
  if (!needle) return list.value.items;
  return list.value.items.filter(chat =>
    `${chat.contact.name} ${previewText(chat.last_message)}`
      .toLowerCase()
      .includes(needle)
  );
});
const firstLoad = computed(
  () => list.value.loading && !list.value.items.length
);
const empty = computed(() => {
  if (query.value.trim())
    return { icon: 'i-lucide-search', title: t('list.empty_search'), text: '' };
  if (filter.value === 'hidden')
    return {
      icon: 'i-lucide-archive',
      title: t('list.empty_hidden'),
      text: t('list.empty_hidden_text'),
    };
  if (filter.value === 'waiting')
    return {
      icon: 'i-lucide-check',
      title: t('list.empty_waiting'),
      text: t('list.empty_waiting_text'),
    };
  return {
    icon: 'i-lucide-message-circle',
    title: t('list.empty_all'),
    text: t('list.empty_all_text'),
  };
});

watch(filter, value => loadList(value), { immediate: true });

onMounted(() => {
  observer = new IntersectionObserver(entries => {
    if (entries.some(entry => entry.isIntersecting)) loadMore();
  });
  if (sentinel.value) observer.observe(sentinel.value);
});
onBeforeUnmount(() => observer?.disconnect());

const openChat = chat => router.push({ name: 'chat', params: { id: chat.id } });
const go = name => {
  menuOpen.value = false;
  router.push({ name });
};
const toggleHidden = async chat => {
  rowMenu.value = null;
  await setHidden(chat.id, !props.hiddenView);
};
</script>

<template>
  <section class="flex h-full w-full flex-col bg-panel">
    <header class="flex h-14 shrink-0 items-center gap-1 px-3">
      <template v-if="hiddenView">
        <button
          type="button"
          class="grid size-10 place-items-center rounded-full text-muted hover:bg-hover"
          :aria-label="t('nav.back')"
          @click="go('chats')"
        >
          <span class="i-lucide-arrow-left size-5" />
        </button>
        <h1 class="flex-1 text-lg font-semibold">{{ t('nav.hidden') }}</h1>
      </template>
      <template v-else>
        <h1 class="flex-1 px-1 text-xl font-semibold">{{ t('nav.chats') }}</h1>
        <div class="relative">
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
            @click.stop
          >
            <button
              type="button"
              class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
              @click="go('hidden')"
            >
              <span class="i-lucide-archive size-5 text-muted" />{{
                t('nav.hidden')
              }}
            </button>
            <button
              type="button"
              class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
              @click="go('settings')"
            >
              <span class="i-lucide-settings size-5 text-muted" />{{
                t('nav.settings')
              }}
            </button>
          </div>
        </div>
      </template>
    </header>

    <label class="mx-3 mb-2 flex items-center gap-3 rounded-lg bg-chip px-3">
      <span class="i-lucide-search size-4 text-faint" />
      <input
        v-model="query"
        type="search"
        class="h-9 w-full bg-transparent text-sm outline-none placeholder:text-faint"
        :placeholder="t('search.placeholder')"
        :aria-label="t('search.placeholder')"
      />
    </label>

    <div v-if="!hiddenView" class="flex gap-2 px-3 pb-2">
      <button
        v-for="name in ['waiting', 'all']"
        :key="name"
        type="button"
        :aria-pressed="tab === name"
        class="h-8 rounded-full px-3 text-sm"
        :class="
          tab === name ? 'bg-accent-soft text-accent-ink' : 'bg-chip text-muted'
        "
        @click="tab = name"
      >
        {{ t(`tab.${name}`) }}
        <span
          v-if="name === 'waiting' && list.waitingCount"
          class="ms-1 font-semibold"
        >
          {{ list.waitingCount }}
        </span>
      </button>
    </div>

    <div class="min-h-0 flex-1 overflow-y-auto">
      <p v-if="hiddenView" class="px-4 py-2 text-xs text-faint">
        {{ t('list.hidden_hint') }}
      </p>
      <button
        v-else-if="list.hiddenCount"
        type="button"
        class="flex w-full items-center gap-6 px-6 py-3 text-start hover:bg-hover"
        @click="go('hidden')"
      >
        <span class="i-lucide-archive size-5 text-muted" />
        <span class="flex-1 font-medium">{{ t('list.hidden_row') }}</span>
        <span class="text-sm text-accent">{{ list.hiddenCount }}</span>
      </button>

      <div v-if="firstLoad" aria-busy="true">
        <div v-for="n in 6" :key="n" class="flex animate-pulse gap-3 px-3 py-3">
          <div class="size-12 rounded-full bg-chip" />
          <div class="flex-1 space-y-2 py-1">
            <div class="h-3 w-2/5 rounded bg-chip" />
            <div class="h-3 w-4/5 rounded bg-chip" />
          </div>
        </div>
      </div>
      <template v-else-if="rows.length">
        <ChatRow
          v-for="chat in rows"
          :key="chat.id"
          :chat="chat"
          :active="chat.id === activeId"
          @open="openChat"
          @menu="rowMenu = $event"
        />
      </template>
      <div v-else class="flex flex-col items-center px-8 py-16 text-center">
        <span class="mb-3 size-10 text-faint" :class="empty.icon" />
        <p class="font-medium">{{ empty.title }}</p>
        <p v-if="empty.text" class="mt-1 text-sm text-muted">
          {{ empty.text }}
        </p>
      </div>
      <div ref="sentinel" class="h-px" />
    </div>

    <BottomSheet
      v-if="rowMenu"
      :title="rowMenu.contact.name"
      @close="rowMenu = null"
    >
      <button
        type="button"
        class="flex w-full items-center gap-3 rounded-lg px-2 py-3 text-start hover:bg-hover"
        @click="toggleHidden(rowMenu)"
      >
        <span
          class="size-5 text-muted"
          :class="hiddenView ? 'i-lucide-archive-restore' : 'i-lucide-archive'"
        />
        {{ hiddenView ? t('menu.unhide') : t('menu.hide') }}
      </button>
    </BottomSheet>
  </section>
</template>
