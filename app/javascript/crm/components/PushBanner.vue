<script setup>
// Over the chat list until push is on (crm/PRD.md, stage P): a missed client message is a lost client. Browsers
// ask for the permission only from a tap, so the first open shows this button instead of the prompt itself.
import { onMounted } from 'vue';
import { errorKey, t } from '../lib/i18n';
import { enablePush, push, pushBannerHidden, refreshPush } from '../lib/push';
import { toast } from '../lib/store';

onMounted(refreshPush);

const enable = async () => {
  try {
    await enablePush();
  } catch (failure) {
    toast(errorKey(failure));
  }
};
</script>

<template>
  <div
    v-if="push !== 'on' && !pushBannerHidden"
    role="status"
    class="mx-3 mb-2 flex items-start gap-3 rounded-lg bg-accent-soft p-3 text-sm text-accent-ink"
  >
    <span class="i-lucide-bell-ring mt-0.5 size-5 shrink-0" />
    <div class="min-w-0 flex-1">
      <p class="font-medium">{{ t('push.banner_title') }}</p>
      <p class="pt-0.5 text-xs">{{ t(`push.banner_${push}`) }}</p>
      <div class="flex gap-2 pt-2">
        <button
          v-if="push === 'off'"
          type="button"
          class="h-8 rounded-full bg-accent px-4 text-sm font-medium text-on-accent"
          @click="enable"
        >
          {{ t('push.enable') }}
        </button>
        <button
          type="button"
          class="h-8 rounded-full px-3 text-sm"
          @click="pushBannerHidden = true"
        >
          {{ t('push.later') }}
        </button>
      </div>
    </div>
  </div>
</template>
