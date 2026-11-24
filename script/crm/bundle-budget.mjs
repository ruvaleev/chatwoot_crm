/* eslint-disable no-console -- a command-line report */
// Size budget of the new interface (crm/PRD.md, AC D.8): what the CRM entry loads at start, gzipped, from the
// production Vite manifest. Lazy chunks (dynamic imports) are not counted. Exits 1 over budget.
// Usage: bin/vite build && node script/crm/bundle-budget.mjs [manifest]
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { gzipSync } from 'node:zlib';
import { pathToFileURL } from 'node:url';

export const ENTRY = 'entrypoints/crm.js';
export const BUDGET = { js: 150 * 1024, css: 30 * 1024 };

// Files the entry needs before first render: itself, its static imports (recursively) and their CSS.
export const startFiles = (manifest, entry = ENTRY) => {
  const seen = new Set();
  const files = { js: new Set(), css: new Set() };
  const visit = key => {
    if (seen.has(key)) return;
    seen.add(key);
    const chunk = manifest[key];
    if (!chunk) throw new Error(`Not in the Vite manifest: ${key}`);
    files.js.add(chunk.file);
    (chunk.css || []).forEach(file => files.css.add(file));
    (chunk.imports || []).forEach(visit);
  };
  visit(entry);
  return { js: [...files.js], css: [...files.css] };
};

const gzipped = (root, files) =>
  files.reduce(
    (sum, file) => sum + gzipSync(readFileSync(join(root, file))).length,
    0
  );

// The whole production build, for the before/after record of stage L3 (crm/PROGRESS.md).
const allFiles = dir =>
  readdirSync(dir, { withFileTypes: true }).flatMap(item =>
    item.isDirectory() ? allFiles(join(dir, item.name)) : [join(dir, item.name)]
  );

const reportBuild = root => {
  const files = allFiles(root);
  const code = files.filter(file => /\.(js|css)$/.test(file));
  const megabytes = bytes => (bytes / 1024 / 1024).toFixed(1);
  const raw = files.reduce((sum, file) => sum + statSync(file).size, 0);
  const gzip = code.reduce(
    (sum, file) => sum + gzipSync(readFileSync(file)).length,
    0
  );
  console.log(
    `All assets: ${files.length} files, ${megabytes(raw)} MB; JS and CSS: ${code.length} files, ${megabytes(gzip)} MB gzip`
  );
};

const main = manifestPath => {
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  const root = dirname(dirname(manifestPath));
  reportBuild(root);
  const files = startFiles(manifest);
  const size = { js: gzipped(root, files.js), css: gzipped(root, files.css) };
  const over = Object.keys(BUDGET).filter(kind => size[kind] > BUDGET[kind]);
  Object.keys(BUDGET).forEach(kind => {
    console.log(
      `CRM ${kind}: ${(size[kind] / 1024).toFixed(1)} KB gzip of ${BUDGET[kind] / 1024} KB (${files[kind].length} files)`
    );
  });
  if (over.length) {
    console.error(`CRM bundle over budget: ${over.join(', ')}`);
    process.exit(1);
  }
};

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv[2] || 'public/vite/.vite/manifest.json');
}
