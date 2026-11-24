<script setup>
import { onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import ChatAvatar from './ChatAvatar.vue';
import TemplatesEditor from './TemplatesEditor.vue';
import ScheduleEditor from './ScheduleEditor.vue';
import { locale, errorKey, t } from '../lib/i18n';
import { signOut } from '../lib/api';
import {
  deleteTemplate,
  fetchTemplateGroups,
  isManager,
  reset,
  saveSettings,
  saveTemplate,
  state,
  toast,
} from '../lib/store';

const router = useRouter();
const THEMES = ['system', 'light', 'dark'];
const LANGUAGES = ['ru', 'en'];

const myTemplates = ref([]);
const busy = ref(false);
const loadTemplates = async () => {
  myTemplates.value = (await fetchTemplateGroups()).personal;
};
const changeTemplates = async action => {
  busy.value = true;
  try {
    await action();
    await loadTemplates();
  } catch (failure) {
    toast(errorKey(failure));
  } finally {
    busy.value = false;
  }
};
const saveMine = template =>
  changeTemplates(() => saveTemplate(template, 'personal'));
const deleteMine = template =>
  changeTemplates(() => deleteTemplate(template, 'personal'));
onMounted(loadTemplates);

const logout = async () => {
  await signOut();
  reset();
  router.replace({ name: 'login' });
};
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
      <h1 class="flex-1 text-lg font-semibold">{{ t('settings.title') }}</h1>
    </header>
    <div class="min-h-0 flex-1 overflow-y-auto">
      <div class="flex items-center gap-4 px-4 py-4">
        <ChatAvatar :name="state.user?.name" size="size-16 text-xl" />
        <div class="min-w-0">
          <p class="truncate text-lg">{{ state.user?.name }}</p>
          <p class="truncate text-sm text-faint">{{ state.user?.email }}</p>
        </div>
      </div>

      <h2 class="px-4 pb-2 pt-4 text-sm font-medium text-accent-ink">
        {{ t('settings.language') }}
      </h2>
      <div class="flex gap-2 px-4">
        <button
          v-for="code in LANGUAGES"
          :key="code"
          type="button"
          :aria-pressed="locale === code"
          class="h-9 rounded-full px-4 text-sm"
          :class="
            locale === code
              ? 'bg-accent-soft text-accent-ink'
              : 'bg-chip text-muted'
          "
          @click="saveSettings({ crm_locale: code })"
        >
          {{ t(`lang.${code}`) }}
        </button>
      </div>

      <h2 class="px-4 pb-2 pt-6 text-sm font-medium text-accent-ink">
        {{ t('settings.theme') }}
      </h2>
      <div class="flex flex-wrap gap-2 px-4">
        <button
          v-for="theme in THEMES"
          :key="theme"
          type="button"
          :aria-pressed="(state.uiSettings.crm_theme || 'system') === theme"
          class="h-9 rounded-full px-4 text-sm"
          :class="
            (state.uiSettings.crm_theme || 'system') === theme
              ? 'bg-accent-soft text-accent-ink'
              : 'bg-chip text-muted'
          "
          @click="saveSettings({ crm_theme: theme })"
        >
          {{ t(`theme.${theme}`) }}
        </button>
      </div>

      <template v-if="!isManager">
        <h2 class="px-4 pb-2 pt-6 text-sm font-medium text-accent-ink">
          {{ t('schedule.title') }}
        </h2>
        <div class="px-4">
          <ScheduleEditor />
        </div>
      </template>

      <h2 class="px-4 pb-2 pt-6 text-sm font-medium text-accent-ink">
        {{ t('settings.my_templates') }}
      </h2>
      <div class="px-4">
        <TemplatesEditor
          :templates="myTemplates"
          :busy="busy"
          @save="saveMine"
          @delete="deleteMine"
        />
      </div>

      <button
        type="button"
        class="mt-8 flex w-full items-center gap-4 px-4 py-3 text-start text-danger hover:bg-hover"
        @click="logout"
      >
        <span class="i-lucide-log-out size-5" />{{ t('settings.logout') }}
      </button>
    </div>
  </section>
</template>
