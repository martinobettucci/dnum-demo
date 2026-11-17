// Construction du front en deux fichiers (ADR-002, ADR-006 §2), exécutée dans l'étape node:22.12.0-alpine
// de app/Dockerfile après « npm ci » :
//   dist/vendor/supabase.js  : bundle de @supabase/supabase-js@2.47.10 seul (entrée src/vendor.js) ;
//   dist/app.js              : code applicatif seul ; importe /vendor/supabase.js, externe au bundle.
import { build } from 'esbuild';
import { cp, mkdir } from 'node:fs/promises';

const commun = {
  bundle: true,
  format: 'esm',
  target: 'es2020',
  minify: true,
  legalComments: 'none',
  define: { 'process.env.NODE_ENV': '"production"' },
};

await mkdir('dist/vendor', { recursive: true });
await build({ ...commun, entryPoints: ['src/vendor.js'], outfile: 'dist/vendor/supabase.js' });
await build({
  ...commun,
  entryPoints: ['src/app.js'],
  outfile: 'dist/app.js',
  external: ['/vendor/supabase.js'],
});
await cp('index.html', 'dist/index.html');
await cp('style.css', 'dist/style.css');
console.log('front : dist/app.js, dist/vendor/supabase.js, dist/index.html, dist/style.css');
