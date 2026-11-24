<script setup>
import { reactive, ref } from 'vue';
import { t } from '../lib/i18n';

const props = defineProps({
  templates: { type: Array, required: true },
  busy: { type: Boolean, default: false },
});
const emit = defineEmits(['save', 'delete']);

const editing = ref(null);
const draft = reactive({ short_code: '', content: '' });

const open = template => {
  editing.value = template || {};
  Object.assign(draft, {
    short_code: template?.short_code || '',
    content: template?.content || '',
  });
};

const save = () => {
  emit('save', { id: editing.value.id, ...draft });
  editing.value = null;
};
</script>

<!-- A list of reply templates with an inline form: used for the team's and for one's own. -->
<template>
  <div>
    <ul v-if="props.templates.length" class="mb-3 space-y-1">
      <li
        v-for="template in props.templates"
        :key="template.id"
        class="flex items-start gap-2 rounded-lg bg-chip px-3 py-2"
      >
        <button
          type="button"
          class="min-w-0 flex-1 text-start"
          @click="open(template)"
        >
          <span class="block text-xs font-medium text-accent-ink">
            /{{ template.short_code }}
          </span>
          <span class="block truncate text-sm">{{ template.content }}</span>
        </button>
        <button
          type="button"
          class="grid size-8 shrink-0 place-items-center rounded-full text-muted hover:bg-hover"
          :aria-label="t('templates.delete')"
          :disabled="props.busy"
          @click="emit('delete', template)"
        >
          <span class="i-lucide-trash-2 size-4" />
        </button>
      </li>
    </ul>
    <p v-else class="mb-3 text-sm text-muted">{{ t('templates.empty') }}</p>

    <form
      v-if="editing"
      class="space-y-2 rounded-lg border border-line p-3"
      @submit.prevent="save"
    >
      <input
        v-model="draft.short_code"
        type="text"
        required
        class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
        :placeholder="t('templates.short_code')"
        :aria-label="t('templates.short_code')"
      />
      <textarea
        v-model="draft.content"
        rows="3"
        required
        class="w-full rounded-lg border border-line bg-panel px-3 py-2 outline-none focus:border-accent"
        :placeholder="t('templates.content')"
        :aria-label="t('templates.content')"
      />
      <div class="flex gap-2">
        <button
          type="button"
          class="h-10 flex-1 rounded-lg bg-chip text-sm text-muted"
          @click="editing = null"
        >
          {{ t('composer.cancel') }}
        </button>
        <button
          type="submit"
          class="h-10 flex-1 rounded-lg bg-accent text-sm font-medium text-on-accent disabled:opacity-50"
          :disabled="props.busy"
        >
          {{ t('profile.save') }}
        </button>
      </div>
    </form>
    <button
      v-else
      type="button"
      class="flex h-10 items-center gap-2 rounded-lg px-2 text-sm font-medium text-accent hover:bg-hover"
      @click="open(null)"
    >
      <span class="i-lucide-plus size-4" />
      {{ t('templates.add') }}
    </button>
  </div>
</template>
