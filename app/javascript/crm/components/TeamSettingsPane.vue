<script setup>
import { onMounted, reactive, ref, toRaw } from 'vue';
import { useRouter } from 'vue-router';
import TemplatesEditor from './TemplatesEditor.vue';
import { t } from '../lib/i18n';
import {
  createLabel,
  deleteLabel,
  deleteTemplate,
  fetchLabelRecords,
  fetchTemplateGroups,
  saveTeamSettings,
  saveTemplate,
  state,
  toast,
} from '../lib/store';

const router = useRouter();

const LOCALES = ['ru', 'en'];
// A copy to edit: structuredClone can't copy the reactive proxy itself.
const form = reactive(structuredClone(toRaw(state.settings)));
const newReason = ref('');
const labels = ref([]);
const newLabel = ref('');
const teamTemplates = ref([]);
const busy = ref(false);

const run = async (action, savedToast = 'toast.saved') => {
  busy.value = true;
  try {
    await action();
    if (savedToast) toast(savedToast);
  } catch {
    toast('error.generic');
  } finally {
    busy.value = false;
  }
};

const loadLabels = async () => {
  labels.value = await fetchLabelRecords();
};
const loadTemplates = async () => {
  teamTemplates.value = (await fetchTemplateGroups()).team;
};

const addReason = () => {
  const reason = newReason.value.trim();
  if (reason && !form.lost_reasons.includes(reason))
    form.lost_reasons.push(reason);
  newReason.value = '';
};
const removeReason = reason => {
  form.lost_reasons = form.lost_reasons.filter(item => item !== reason);
};

const save = () =>
  run(() =>
    saveTeamSettings({
      ...form,
      overdue_minutes: Number(form.overdue_minutes),
      overdue_minutes_off_hours: Number(form.overdue_minutes_off_hours),
    })
  );

const addLabel = () =>
  run(async () => {
    await createLabel(newLabel.value.trim());
    newLabel.value = '';
    await loadLabels();
  });
const removeLabel = label =>
  run(async () => {
    await deleteLabel(label.id);
    await loadLabels();
  }, null);

const saveTeamTemplate = template =>
  run(async () => {
    await saveTemplate(template, 'team');
    await loadTemplates();
  });
const removeTeamTemplate = template =>
  run(async () => {
    await deleteTemplate(template, 'team');
    await loadTemplates();
  }, null);

onMounted(() => Promise.all([loadLabels(), loadTemplates()]));
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
      <h1 class="flex-1 text-lg font-semibold">{{ t('team.title') }}</h1>
    </header>

    <div class="min-h-0 flex-1 overflow-y-auto px-4 pb-8">
      <form @submit.prevent="save">
        <h2 class="mb-2 mt-2 text-sm font-medium text-accent-ink">
          {{ t('team.overdue') }}
        </h2>
        <div class="mb-5 flex gap-3">
          <label class="flex-1">
            <span class="mb-1 block text-xs text-muted">
              {{ t('team.overdue_work') }}
            </span>
            <input
              v-model="form.overdue_minutes"
              type="number"
              min="1"
              required
              class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
            />
          </label>
          <label class="flex-1">
            <span class="mb-1 block text-xs text-muted">
              {{ t('team.overdue_off') }}
            </span>
            <input
              v-model="form.overdue_minutes_off_hours"
              type="number"
              min="1"
              required
              class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
            />
          </label>
        </div>

        <h2 class="mb-2 text-sm font-medium text-accent-ink">
          {{ t('team.notification_language') }}
        </h2>
        <div class="mb-5 flex gap-2">
          <button
            v-for="code in LOCALES"
            :key="code"
            type="button"
            class="h-8 rounded-full px-3 text-sm"
            :class="
              form.notification_locale === code
                ? 'bg-accent text-on-accent'
                : 'bg-chip text-muted'
            "
            @click="form.notification_locale = code"
          >
            {{ t(`lang.${code}`) }}
          </button>
        </div>

        <h2 class="mb-2 text-sm font-medium text-accent-ink">
          {{ t('team.lost_reasons') }}
        </h2>
        <div class="mb-2 flex flex-wrap gap-2">
          <span
            v-for="reason in form.lost_reasons"
            :key="reason"
            class="flex h-8 items-center gap-1 rounded-full bg-chip text-sm text-muted ps-3 pe-1"
          >
            {{ reason }}
            <button
              type="button"
              class="grid size-6 place-items-center rounded-full hover:bg-hover"
              :aria-label="t('templates.delete')"
              @click="removeReason(reason)"
            >
              <span class="i-lucide-x size-3.5" />
            </button>
          </span>
        </div>
        <div class="mb-5 flex gap-2">
          <input
            v-model="newReason"
            type="text"
            class="h-10 flex-1 rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
            :placeholder="t('team.new_reason')"
            :aria-label="t('team.new_reason')"
            @keydown.enter.prevent="addReason"
          />
          <button
            type="button"
            class="h-10 rounded-lg bg-chip px-3 text-sm text-ink"
            @click="addReason"
          >
            {{ t('team.add') }}
          </button>
        </div>

        <button
          type="submit"
          class="mb-8 h-11 w-full rounded-lg bg-accent font-medium text-on-accent disabled:opacity-50"
          :disabled="busy"
        >
          {{ t('profile.save') }}
        </button>
      </form>

      <h2 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('labels.title') }}
      </h2>
      <div class="mb-2 flex flex-wrap gap-2">
        <span
          v-for="label in labels"
          :key="label.id"
          class="flex h-8 items-center gap-1 rounded-full border border-line text-sm text-muted ps-3 pe-1"
        >
          {{ label.title }}
          <button
            type="button"
            class="grid size-6 place-items-center rounded-full hover:bg-hover"
            :aria-label="t('templates.delete')"
            :disabled="busy"
            @click="removeLabel(label)"
          >
            <span class="i-lucide-x size-3.5" />
          </button>
        </span>
      </div>
      <p class="mb-2 text-xs text-faint">{{ t('team.label_hint') }}</p>
      <form class="mb-8 flex gap-2" @submit.prevent="addLabel">
        <input
          v-model="newLabel"
          type="text"
          required
          class="h-10 flex-1 rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
          :placeholder="t('team.new_label')"
          :aria-label="t('team.new_label')"
        />
        <button
          type="submit"
          class="h-10 rounded-lg bg-chip px-3 text-sm text-ink disabled:opacity-50"
          :disabled="busy"
        >
          {{ t('team.add') }}
        </button>
      </form>

      <h2 class="mb-2 text-sm font-medium text-accent-ink">
        {{ t('team.templates') }}
      </h2>
      <TemplatesEditor
        :templates="teamTemplates"
        :busy="busy"
        @save="saveTeamTemplate"
        @delete="removeTeamTemplate"
      />
    </div>
  </section>
</template>
