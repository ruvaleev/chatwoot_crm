<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import ChatList from '../components/ChatList.vue';
import ChatView from '../components/ChatView.vue';
import SettingsPane from '../components/SettingsPane.vue';
import NumbersPane from '../components/NumbersPane.vue';
import FreelancersPane from '../components/FreelancersPane.vue';
import TeamSettingsPane from '../components/TeamSettingsPane.vue';
import { t } from '../lib/i18n';
import { closeChat } from '../lib/store';

const route = useRoute();
const chatId = computed(() =>
  route.name === 'chat' ? Number(route.params.id) : null
);
</script>

<!-- Like WhatsApp: list and chat side by side on a wide screen, one at a time on a phone. -->
<template>
  <div class="flex h-full">
    <aside
      class="h-full w-full shrink-0 border-e border-line md:w-[380px] lg:w-[420px]"
      :class="chatId ? 'hidden md:flex' : 'flex'"
    >
      <SettingsPane v-if="route.name === 'settings'" />
      <NumbersPane v-else-if="route.name === 'numbers'" />
      <FreelancersPane v-else-if="route.name === 'freelancers'" />
      <TeamSettingsPane v-else-if="route.name === 'team'" />
      <ChatList
        v-else
        :hidden-view="route.name === 'hidden'"
        :active-id="chatId"
      />
    </aside>
    <main
      class="h-full min-w-0 flex-1"
      :class="chatId ? 'flex' : 'hidden md:flex'"
    >
      <ChatView v-if="chatId" :id="chatId" @vue:unmounted="closeChat" />
      <div
        v-else
        class="flex flex-1 flex-col items-center justify-center gap-3 bg-head text-muted"
      >
        <span class="i-lucide-messages-square size-12 text-faint" />
        <p>{{ t('chat.select') }}</p>
      </div>
    </main>
  </div>
</template>
