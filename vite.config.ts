import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';
// CRM: only our entrypoints in the production build (crm/docs/core-changes.md)
import { crmEntrypoints } from './custom/config/vite_entrypoints.js';

export default defineConfig({
  plugins: [ruby(), vue(vueOptions), yaml(), crmEntrypoints()],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
  },
  resolve: { alias: aliases },
});
