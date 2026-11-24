<script setup>
import { state } from './lib/store';
</script>

<template>
  <div class="h-full font-sans text-[15px] text-ink antialiased">
    <router-view />
    <transition
      enter-from-class="opacity-0 translate-y-2"
      leave-to-class="opacity-0"
      enter-active-class="transition duration-200"
      leave-active-class="transition duration-200"
    >
      <div
        v-if="state.toast"
        role="status"
        class="fixed inset-x-4 bottom-24 z-50 mx-auto max-w-sm rounded-lg bg-ink px-4 py-3 text-center text-sm text-panel shadow-pop md:bottom-8"
      >
        {{ state.toast }}
      </div>
    </transition>
  </div>
</template>
