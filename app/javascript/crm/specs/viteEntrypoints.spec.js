import { describe, it, expect } from 'vitest';
import {
  CRM_ENTRYPOINTS,
  crmEntrypoints,
} from '../../../../custom/config/vite_entrypoints';

describe('production entrypoints', () => {
  const plugin = crmEntrypoints();

  it('builds only the CRM and super admin', () => {
    const input = Object.fromEntries(
      [
        ...CRM_ENTRYPOINTS,
        'entrypoints/dashboard.js',
        'entrypoints/widget.js',
      ].map(name => [name, name])
    );
    plugin.config({ build: { rollupOptions: { input } } });

    expect(Object.keys(input)).toEqual(CRM_ENTRYPOINTS);
  });

  it('keeps everything outside the production build', () => {
    expect(plugin.apply({}, { command: 'build', mode: 'production' })).toBe(
      true
    );
    expect(plugin.apply({}, { command: 'build', mode: 'test' })).toBe(false);
    expect(plugin.apply({}, { command: 'serve', mode: 'development' })).toBe(
      false
    );
  });
});
