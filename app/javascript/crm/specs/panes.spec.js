// Screens behind a role: render them here, since a broken setup leaves the page blank without an error UI.
import { describe, it, expect, vi } from 'vitest';
import { flushPromises, mount } from '@vue/test-utils';
import TeamSettingsPane from '../components/TeamSettingsPane.vue';
import SettingsPane from '../components/SettingsPane.vue';
import NumbersPane from '../components/NumbersPane.vue';
import FreelancersPane from '../components/FreelancersPane.vue';
import { setLocale } from '../lib/i18n';

vi.mock('vue-router', () => ({ useRouter: () => ({ push: vi.fn() }) }));
vi.mock('../lib/store', async () => {
  const { reactive, ref } = await import('vue');
  return {
    state: reactive({
      settings: {
        lost_reasons: ['Дорого'],
        overdue_minutes: 10,
        overdue_minutes_off_hours: 60,
        notification_locale: 'ru',
      },
      user: {
        name: 'Anna',
        email: 'anna.v@crm.invalid',
        custom_attributes: {
          crm_schedule: {
            time_zone: 'Asia/Bangkok',
            days: [1, 2],
            from: '10:00',
            to: '19:00',
          },
        },
      },
      uiSettings: {},
    }),
    isManager: ref(false),
    now: ref(Date.now()),
    fetchLabelRecords: vi.fn(async () => [{ id: 1, title: 'балабол' }]),
    fetchTemplateGroups: vi.fn(async () => ({
      team: [{ id: 1, short_code: 'hello', content: 'Hi' }],
      personal: [],
    })),
    createLabel: vi.fn(),
    deleteLabel: vi.fn(),
    saveTemplate: vi.fn(),
    deleteTemplate: vi.fn(),
    saveTeamSettings: vi.fn(),
    saveSettings: vi.fn(),
    saveSchedule: vi.fn(),
    reset: vi.fn(),
    toast: vi.fn(),
    fetchNumbers: vi.fn(async () => ({
      payload: [
        {
          id: 2,
          name: 'Номер 1',
          instance: 'number-1',
          state: 'open',
          freelancer: { id: 5, name: 'Anna' },
        },
      ],
      freelancers: [{ id: 5, name: 'Anna' }],
    })),
    addNumber: vi.fn(),
    connectNumber: vi.fn(),
    assignNumber: vi.fn(),
    restartNumber: vi.fn(),
    logoutNumber: vi.fn(),
    fetchFreelancers: vi.fn(async () => ({
      payload: [
        {
          id: 5,
          name: 'Anna',
          login: 'anna.v',
          number: { id: 2, name: 'Номер 1' },
          clients_count: 3,
          invited: true,
          schedule: null,
        },
      ],
      numbers: [{ id: 2, name: 'Номер 1', freelancer_id: 5 }],
    })),
    addFreelancer: vi.fn(),
    moveFreelancer: vi.fn(),
    inviteFreelancer: vi.fn(),
    removeFreelancer: vi.fn(),
  };
});
vi.mock('../lib/api', () => ({ signOut: vi.fn() }));

describe('screens', () => {
  it('renders the team settings without working hours (they are each freelancer’s)', async () => {
    setLocale('ru');
    const wrapper = mount(TeamSettingsPane);
    await flushPromises();

    expect(wrapper.text()).toContain('Пока фрилансер работает');
    expect(wrapper.find('input[type="time"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('Дорого');
    expect(wrapper.text()).toContain('балабол');
    expect(wrapper.text()).toContain('/hello');
  });

  it('renders the freelancer settings with their schedule and templates', async () => {
    const wrapper = mount(SettingsPane);
    await flushPromises();

    expect(wrapper.text()).toContain('Моё расписание');
    expect(wrapper.text()).toContain('Мои шаблоны');
    expect(wrapper.find('input[type="time"]').element.value).toBe('10:00');
  });

  it('renders the numbers with their state and freelancer', async () => {
    const wrapper = mount(NumbersPane);
    await flushPromises();

    expect(wrapper.text()).toContain('Номер 1');
    expect(wrapper.text()).toContain('Anna');
    expect(wrapper.text()).toContain('Подключён');
  });

  it('renders the freelancers with their number, clients and schedule', async () => {
    const wrapper = mount(FreelancersPane);
    await flushPromises();

    expect(wrapper.text()).toContain('Номер 1 · клиентов: 3');
    expect(wrapper.text()).toContain('ещё не входил');
    expect(wrapper.text()).toContain('расписание не указано');
  });
});
