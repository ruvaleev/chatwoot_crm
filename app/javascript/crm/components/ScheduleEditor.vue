<script setup>
import { reactive, ref, toRaw } from 'vue';
import { locale, errorKey, t } from '../lib/i18n';
import { saveSchedule, state, toast } from '../lib/store';

const DAYS = [1, 2, 3, 4, 5, 6, 7];
const TIME_ZONES = Intl.supportedValuesOf('timeZone');
// Until the freelancer sets it: their own time zone and a plain working week.
const START = {
  time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  days: [1, 2, 3, 4, 5],
  from: '10:00',
  to: '19:00',
};

// 2026-11-23 is a Monday: day n of the week is the day before it plus n.
const dayName = day =>
  new Intl.DateTimeFormat(locale.value, { weekday: 'short' }).format(
    new Date(Date.UTC(2026, 10, 22 + day))
  );

// A copy to edit: structuredClone can't copy the reactive proxy itself.
const form = reactive(
  structuredClone(toRaw(state.user.custom_attributes?.crm_schedule) || START)
);
const busy = ref(false);

const toggleDay = day => {
  form.days = form.days.includes(day)
    ? form.days.filter(item => item !== day)
    : [...form.days, day].sort();
};

const save = async () => {
  busy.value = true;
  try {
    await saveSchedule({ ...form });
    toast('toast.saved');
  } catch (failure) {
    toast(errorKey(failure));
  } finally {
    busy.value = false;
  }
};
</script>

<template>
  <form @submit.prevent="save">
    <p class="mb-3 text-xs text-muted">{{ t('schedule.hint') }}</p>
    <label class="mb-3 block">
      <span class="mb-1 block text-xs text-muted">
        {{ t('schedule.time_zone') }}
      </span>
      <input
        v-model="form.time_zone"
        type="text"
        list="crm-time-zones"
        required
        class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
      />
      <datalist id="crm-time-zones">
        <option v-for="zone in TIME_ZONES" :key="zone" :value="zone" />
      </datalist>
    </label>
    <div class="mb-3 flex flex-wrap gap-1.5">
      <button
        v-for="day in DAYS"
        :key="day"
        type="button"
        class="h-8 min-w-10 rounded-full px-2 text-sm"
        :class="
          form.days.includes(day)
            ? 'bg-accent text-on-accent'
            : 'bg-chip text-muted'
        "
        :aria-pressed="form.days.includes(day)"
        @click="toggleDay(day)"
      >
        {{ dayName(day) }}
      </button>
    </div>
    <div class="mb-3 flex gap-3">
      <label class="flex-1">
        <span class="mb-1 block text-xs text-muted">
          {{ t('schedule.from') }}
        </span>
        <input
          v-model="form.from"
          type="time"
          required
          class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
        />
      </label>
      <label class="flex-1">
        <span class="mb-1 block text-xs text-muted">
          {{ t('schedule.to') }}
        </span>
        <input
          v-model="form.to"
          type="time"
          required
          class="h-10 w-full rounded-lg border border-line bg-panel px-3 outline-none focus:border-accent"
        />
      </label>
    </div>
    <button
      type="submit"
      class="h-10 w-full rounded-lg bg-accent text-sm font-medium text-on-accent disabled:opacity-50"
      :disabled="busy"
    >
      {{ t('profile.save') }}
    </button>
  </form>
</template>
