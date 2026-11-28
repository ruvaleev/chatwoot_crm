<script setup>
import { computed } from 'vue';
import { initials } from '../lib/format';

const props = defineProps({
  name: { type: String, default: '' },
  size: { type: String, default: 'size-12' },
});
const letters = computed(() => initials(props.name));
</script>

<template>
  <div
    class="grid shrink-0 place-items-center rounded-full bg-chip font-medium text-muted"
    :class="size"
    aria-hidden="true"
  >
    <span v-if="letters">{{ letters }}</span>
    <span v-else class="i-lucide-user size-1/2" />
  </div>
</template>
