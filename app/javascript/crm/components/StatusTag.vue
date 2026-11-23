<script setup>
import { t } from '../lib/i18n';

defineProps({ status: { type: String, required: true } });

const TONES = {
  new: 'bg-accent-soft text-accent-ink',
  qualifying: 'bg-chip text-muted',
  handed_off: 'bg-accent-soft text-accent-ink',
  in_work: 'bg-chip text-muted',
  won: 'bg-ok-soft text-ok',
  lost: 'bg-chip text-faint',
  spam: 'bg-danger-soft text-danger',
};
</script>

<template>
  <span
    class="inline-flex h-5 items-center whitespace-nowrap rounded-md px-1.5 text-xs"
    :class="TONES[status]"
  >
    {{ t(`status.${status}`) }}
  </span>
</template>
