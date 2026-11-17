// Construction du front en deux fichiers (ADR-002, ADR-006 §2), exécutée dans l'étape node:22.12.0-alpine
// de app/Dockerfile après « npm ci » :
//   dist/vendor/supabase.js  : bundle de @supabase/supabase-js@2.47.10 seul (entrée src/vendor.js) ;
//   dist/app.js              : code applicatif seul ; importe /vendor/supabase.js, externe au bundle.
//
// Preuve ADR-010 (points ouverts 1 et 2) : le metafile d'esbuild est écrit dans meta/ (hors dist/, donc
// jamais copié dans l'image nginx finale). Il liste les entrées effectivement incluses dans le bundle.
// Le script affiche la liste des paquets Node-only (whatwg-url, tr46, webidl-conversions, ws,
// @supabase/node-fetch) trouvés dans le bundle, avec leur chemin, pour la décision de l'ADR-010.
//   dist/build-sha256.txt    : empreintes sha256 de dist/app.js et dist/vendor/supabase.js, écrites EN DERNIER
//                              (après leur écriture finale), format « <sha256>  <chemin> » (ADR-006 §2, policy 36).
import { build } from 'esbuild';
import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';

const commun = {
  bundle: true,
  format: 'esm',
  target: 'es2020',
  minify: true,
  legalComments: 'none',
  define: { 'process.env.NODE_ENV': '"production"' },
};

await mkdir('dist/vendor', { recursive: true });
await mkdir('meta', { recursive: true });

const vendor = await build({
  ...commun,
  entryPoints: ['src/vendor.js'],
  outfile: 'dist/vendor/supabase.js',
  metafile: true,
});
await build({
  ...commun,
  entryPoints: ['src/app.js'],
  outfile: 'dist/app.js',
  external: ['/vendor/supabase.js'],
});
await cp('index.html', 'dist/index.html');
await cp('style.css', 'dist/style.css');

await writeFile('meta/vendor-metafile.json', JSON.stringify(vendor.metafile, null, 2));

// Paquets Node-only de ADR-010 : présents dans le bundle ? (liste à consigner, cas A/B/C)
const NODE_ONLY = /node_modules\/(whatwg-url|tr46|webidl-conversions|ws|@supabase\/node-fetch)\//;
const inclus = Object.keys(vendor.metafile.inputs).filter((p) => NODE_ONLY.test(p));
const esbuildDansBundle = Object.keys(vendor.metafile.inputs).filter((p) => /node_modules\/esbuild\//.test(p));
console.log(`metafile : meta/vendor-metafile.json (${Object.keys(vendor.metafile.inputs).length} entrées)`);
console.log(`paquets Node-only dans dist/vendor/supabase.js : ${inclus.length === 0 ? 'aucun' : inclus.join(', ')}`);
console.log(`esbuild dans dist/vendor/supabase.js : ${esbuildDansBundle.length === 0 ? 'non' : 'OUI'}`);
// Empreintes du build : calculées sur les octets finaux de dist/ (après toutes les écritures ci-dessus).
// Deux lignes, dans cet ordre, séparateur de deux espaces (format sha256sum), fin de ligne LF.
const empreinte = async (chemin) => createHash('sha256').update(await readFile(`dist/${chemin}`)).digest('hex');
const empreintes = ['app.js', 'vendor/supabase.js'];
const lignes = await Promise.all(empreintes.map(async (c) => `${await empreinte(c)}  ${c}\n`));
await writeFile('dist/build-sha256.txt', lignes.join(''));

console.log('front : dist/app.js, dist/vendor/supabase.js, dist/index.html, dist/style.css, dist/build-sha256.txt');
console.log(`empreintes : ${lignes.map((l) => l.trim().replace(/  /, ' ')).join(' | ')}`);
