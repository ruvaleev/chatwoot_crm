import { describe, it, expect, vi } from 'vitest';
import { flushPromises, mount } from '@vue/test-utils';
import PushBanner from '../components/PushBanner.vue';
import { push, pushBannerHidden } from '../lib/push';
import { setLocale } from '../lib/i18n';

vi.mock('../lib/store', () => ({
  toast: vi.fn(),
  savePushSubscription: vi.fn(),
  removePushSubscription: vi.fn(),
}));

describe('push banner over the chat list', () => {
  it('tells how to get notifications where the browser can’t yet, until "Later"', async () => {
    setLocale('ru');
    const wrapper = mount(PushBanner);
    await flushPromises();

    expect(wrapper.text()).toContain('не пропустить клиента');
    expect(wrapper.text()).toContain('На экран «Домой»');

    await wrapper.find('button').trigger('click');
    expect(wrapper.find('[role="status"]').exists()).toBe(false);
    pushBannerHidden.value = false;
  });

  it('offers the button while off and is gone once on', async () => {
    const wrapper = mount(PushBanner);
    await flushPromises();
    push.value = 'off';
    await flushPromises();

    expect(wrapper.find('button').text()).toBe('Включить');

    push.value = 'on';
    await flushPromises();
    expect(wrapper.find('[role="status"]').exists()).toBe(false);
  });
});
