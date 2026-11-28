<script setup>
import { onBeforeUnmount, onMounted } from 'vue';
import { t } from '../lib/i18n';

defineProps({ title: { type: String, default: '' } });
const emit = defineEmits(['close']);

const onKey = event => {
  if (event.key === 'Escape') emit('close');
};
onMounted(() => document.addEventListener('keydown', onKey));
onBeforeUnmount(() => document.removeEventListener('keydown', onKey));
</script>

<!-- A bottom sheet on a phone, a centred dialog on a wide screen. -->
<template>
  <div
    class="fixed inset-0 z-40 flex items-end justify-center bg-black/40 md:items-center"
    @click.self="emit('close')"
  >
    <section
      role="dialog"
      aria-modal="true"
      :aria-label="title"
      class="max-h-[85vh] w-full overflow-y-auto rounded-t-2xl bg-panel pb-[env(safe-area-inset-bottom)] shadow-pop md:max-w-md md:rounded-2xl"
    >
      <header
        class="sticky top-0 flex items-center gap-2 bg-panel px-4 pb-2 pt-4"
      >
        <h2 class="flex-1 text-lg font-semibold">{{ title }}</h2>
        <button
          type="button"
          class="grid size-9 place-items-center rounded-full text-muted hover:bg-hover"
          :aria-label="t('sheet.close')"
          @click="emit('close')"
        >
          <span class="i-lucide-x size-5" />
        </button>
      </header>
      <div class="px-4 pb-4">
        <slot />
      </div>
    </section>
  </div>
</template>
