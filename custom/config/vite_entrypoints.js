// The production build carries only what the CRM serves (crm/PRD.md, stage L3): the new interface and super admin.
// Chatwoot's old dashboard, website widget, help center portal, survey and SDK are not built; their pages answer
// 404 or lead to /crm. vite-plugin-ruby adds every file of app/javascript/entrypoints as an input, so this runs after
// it and drops the rest. Development and test keep everything (the old dashboard stays there for comparison).
export const CRM_ENTRYPOINTS = [
  'entrypoints/crm.js',
  'entrypoints/superadmin.js',
  'entrypoints/superadmin.scss',
  'entrypoints/superadmin_pages.js',
];

/** @returns {import('vite').Plugin} */
export const crmEntrypoints = () => ({
  name: 'crm-entrypoints',
  enforce: 'post',
  apply: (_config, { command, mode }) =>
    command === 'build' && mode === 'production',
  config(config) {
    const { input } = config.build.rollupOptions;
    Object.keys(input)
      .filter(name => !CRM_ENTRYPOINTS.includes(name))
      .forEach(name => delete input[name]);
  },
});
