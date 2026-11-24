import { describe, it, expect } from 'vitest';
import { startFiles } from '../../../../script/crm/bundle-budget.mjs';

describe('bundle budget', () => {
  const manifest = {
    'entrypoints/crm.js': {
      file: 'assets/crm.js',
      css: ['assets/crm.css'],
      imports: ['_vue.js', '_shared.js'],
      dynamicImports: ['routes.js'],
    },
    '_vue.js': { file: 'assets/vue.js', imports: ['_shared.js'] },
    '_shared.js': { file: 'assets/shared.js', css: ['assets/shared.css'] },
    'routes.js': { file: 'assets/routes.js' },
  };

  it('counts the entry with its static imports and CSS, not lazy chunks', () => {
    expect(startFiles(manifest)).toEqual({
      js: ['assets/crm.js', 'assets/vue.js', 'assets/shared.js'],
      css: ['assets/crm.css', 'assets/shared.css'],
    });
  });

  it('fails loudly when the entry is missing', () => {
    expect(() => startFiles({})).toThrow('Not in the Vite manifest');
  });
});
