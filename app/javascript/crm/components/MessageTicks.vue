<script setup>
defineProps({ status: { type: String, default: '' } });
</script>

<!-- Delivery state like in a messenger: clock, one tick, two ticks, two coloured ticks, failure. -->
<template>
  <span
    v-if="status === 'progress'"
    class="i-lucide-clock size-3.5 text-faint"
  />
  <span
    v-else-if="status === 'sent'"
    class="i-lucide-check size-4 text-faint"
  />
  <span
    v-else-if="status === 'delivered'"
    class="i-lucide-check-check size-4 text-faint"
  />
  <span
    v-else-if="status === 'read'"
    class="i-lucide-check-check size-4 text-accent"
  />
  <span
    v-else-if="status === 'failed'"
    class="i-lucide-circle-alert size-4 text-danger"
  />
</template>
