<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import ChatRow from './ChatRow.vue';
import BottomSheet from './BottomSheet.vue';
import { t } from '../lib/i18n';
import {
  isManager,
  loadList,
  loadMore,
  setHidden,
  setSort,
  state,
} from '../lib/store';

const props = defineProps({
  hiddenView: { type: Boolean, default: false },
  activeId: { type: Number, default: null },
});
const router = useRouter();

const SEARCH_DELAY = 300;
const SORTS = ['recent', 'waiting'];
const STATUSES = [
  'new',
  'qualifying',
  'handed_off',
  'in_work',
  'won',
  'lost',
  'spam',
];
const EMPTY = {
  hidden: ['i-lucide-archive', 'list.empty_hidden', 'list.empty_hidden_text'],
  waiting: ['i-lucide-check', 'list.empty_waiting', 'list.empty_waiting_text'],
  new: ['i-lucide-inbox', 'list.empty_new', 'list.empty_new_text'],
  mine: ['i-lucide-user', 'list.empty_mine', 'list.empty_mine_text'],
  all: ['i-lucide-message-circle', 'list.empty_all', 'list.empty_all_text'],
};

const tab = ref('waiting');
const search = ref(state.list.query);
const menuOpen = ref(false);
const filterOpen = ref(false);
const rowMenu = ref(null);
const sentinel = ref(null);
let observer = null;
let searchTimer = null;

const list = computed(() => state.list);
const tabs = computed(() =>
  isManager.value ? ['waiting', 'new', 'mine', 'all'] : ['waiting', 'all']
);
const filter = computed(() => (props.hiddenView ? 'hidden' : tab.value));
const firstLoad = computed(
  () => list.value.loading && !list.value.items.length
);
const activeInbox = computed(() =>
  list.value.inboxes.find(inbox => inbox.id === list.value.inboxId)
);
const empty = computed(() => {
  if (list.value.query.trim())
    return ['i-lucide-search', 'list.empty_search', ''];
  return EMPTY[filter.value];
});

watch(filter, value => loadList({ filter: value }), { immediate: true });
watch(search, value => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => loadList({ query: value }), SEARCH_DELAY);
});

onMounted(() => {
  observer = new IntersectionObserver(entries => {
    if (entries.some(entry => entry.isIntersecting)) loadMore();
  });
  if (sentinel.value) observer.observe(sentinel.value);
});
onBeforeUnmount(() => {
  observer?.disconnect();
  clearTimeout(searchTimer);
});

const openChat = chat => router.push({ name: 'chat', params: { id: chat.id } });
const go = name => {
  menuOpen.value = false;
  router.push({ name });
};
const toggleHidden = async chat => {
  rowMenu.value = null;
  await setHidden(chat.id, !props.hiddenView);
};
const setFilter = changes => loadList(changes);
const count = name => list.value.counts[name] || 0;
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
        <button
          type="button"
          class="grid size-10 place-items-center rounded-full text-muted hover:bg-hover"
          :aria-label="t('filter.open')"
          @click="filterOpen = true"
        >
          <span class="i-lucide-sliders-horizontal size-5" />
        </button>
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
          >
            <button
              type="button"
              class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
              @click="go('hidden')"
            >
              <span class="i-lucide-archive size-5 text-muted" />
              {{ t('nav.hidden') }}
            </button>
            <button
              v-if="isManager"
              type="button"
              class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
              @click="go('numbers')"
            >
              <span class="i-lucide-smartphone size-5 text-muted" />
              {{ t('nav.numbers') }}
            </button>
            <button
              type="button"
              class="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-hover"
              @click="go('settings')"
            >
              <span class="i-lucide-settings size-5 text-muted" />
              {{ t('nav.settings') }}
            </button>
          </div>
        </div>
      </template>
    </header>

    <label class="mx-3 mb-2 flex items-center gap-3 rounded-lg bg-chip px-3">
      <span class="i-lucide-search size-4 text-faint" />
      <input
        v-model="search"
        type="search"
        class="h-9 w-full bg-transparent text-sm outline-none placeholder:text-faint"
        :placeholder="
          isManager ? t('search.placeholder_manager') : t('search.placeholder')
        "
        :aria-label="t('search.placeholder')"
      />
    </label>

    <div v-if="!hiddenView" class="flex flex-wrap gap-2 px-3 pb-2">
      <button
        v-for="name in tabs"
        :key="name"
        type="button"
        class="h-8 rounded-full px-3 text-sm"
        :class="
          tab === name ? 'bg-accent-soft text-accent-ink' : 'bg-chip text-muted'
        "
        :aria-pressed="tab === name"
        @click="tab = name"
      >
        {{ t(`tab.${name}`) }}
        <span v-if="name !== 'all' && count(name)" class="ms-1 font-semibold">
          {{ count(name) }}
        </span>
      </button>
      <button
        v-if="activeInbox"
        type="button"
        class="flex h-8 items-center gap-1 rounded-full bg-accent text-sm text-on-accent ps-3 pe-2"
        @click="setFilter({ inboxId: null })"
      >
        {{ activeInbox.name }}
        <span class="i-lucide-x size-4" />
      </button>
      <button
        v-if="list.status"
        type="button"
        class="flex h-8 items-center gap-1 rounded-full bg-accent text-sm text-on-accent ps-3 pe-2"
        @click="setFilter({ status: null })"
      >
        {{ t(`status.${list.status}`) }}
        <span class="i-lucide-x size-4" />
      </button>
    </div>

    <div class="min-h-0 flex-1 overflow-y-auto">
      <p v-if="hiddenView" class="px-4 py-2 text-xs text-faint">
        {{ t('list.hidden_hint') }}
      </p>
      <button
        v-else-if="list.counts.hidden"
        type="button"
        class="flex w-full items-center gap-6 px-6 py-3 text-start hover:bg-hover"
        @click="go('hidden')"
      >
        <span class="i-lucide-archive size-5 text-muted" />
        <span class="flex-1 font-medium">{{ t('list.hidden_row') }}</span>
        <span class="text-sm text-accent">{{ list.counts.hidden }}</span>
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
      <template v-else-if="list.items.length">
        <ChatRow
          v-for="chat in list.items"
          :key="chat.id"
          :chat="chat"
          :active="chat.id === activeId"
          :manager="isManager"
          @open="openChat"
          @menu="rowMenu = $event"
        />
      </template>
      <div v-else class="flex flex-col items-center px-8 py-16 text-center">
        <span class="mb-3 size-10 text-faint" :class="empty[0]" />
        <p class="font-medium">{{ t(empty[1]) }}</p>
        <p v-if="empty[2]" class="mt-1 text-sm text-muted">{{ t(empty[2]) }}</p>
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

    <BottomSheet
      v-if="filterOpen"
      :title="t('filter.open')"
      @close="filterOpen = false"
    >
      <h3 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('sort.title') }}
      </h3>
      <div class="mb-5 flex flex-wrap gap-2">
        <button
          v-for="sort in SORTS"
          :key="sort"
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            list.sort === sort
              ? 'bg-accent text-on-accent'
              : 'bg-chip text-muted'
          "
          :aria-pressed="list.sort === sort"
          @click="setSort(sort)"
        >
          {{ t(`sort.${sort}`) }}
        </button>
      </div>
      <h3 v-if="isManager" class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('filter.number') }}
      </h3>
      <div v-if="isManager" class="mb-5 flex flex-wrap gap-2">
        <button
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            list.inboxId ? 'bg-chip text-muted' : 'bg-accent text-on-accent'
          "
          @click="setFilter({ inboxId: null })"
        >
          {{ t('filter.all_numbers') }}
        </button>
        <button
          v-for="inbox in list.inboxes"
          :key="inbox.id"
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            list.inboxId === inbox.id
              ? 'bg-accent text-on-accent'
              : 'bg-chip text-muted'
          "
          @click="setFilter({ inboxId: inbox.id })"
        >
          {{ inbox.name }}
        </button>
      </div>
      <h3 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('filter.status') }}
      </h3>
      <div class="mb-5 flex flex-wrap gap-2">
        <button
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            list.status ? 'bg-chip text-muted' : 'bg-accent text-on-accent'
          "
          @click="setFilter({ status: null })"
        >
          {{ t('filter.all_statuses') }}
        </button>
        <button
          v-for="status in STATUSES"
          :key="status"
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          :class="
            list.status === status
              ? 'bg-accent text-on-accent'
              : 'bg-chip text-muted'
          "
          @click="setFilter({ status })"
        >
          {{ t(`status.${status}`) }}
        </button>
      </div>
      <button
        type="button"
        class="h-10 w-full rounded-lg bg-chip text-sm text-muted"
        @click="setFilter({ inboxId: null, status: null })"
      >
        {{ t('filter.clear') }}
      </button>
    </BottomSheet>
  </section>
</template>
