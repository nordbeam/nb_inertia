import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';
import { readdirSync, statSync } from 'fs';

// Recursively find all .tsx and .ts files to use as entry points
function getEntryPoints(dir, baseDir = null) {
  if (!baseDir) baseDir = dir;
  const entries = {};
  const files = readdirSync(dir);

  for (const file of files) {
    const fullPath = resolve(dir, file);
    const stat = statSync(fullPath);

    if (stat.isDirectory()) {
      Object.assign(entries, getEntryPoints(fullPath, baseDir));
    } else if ((file.endsWith('.tsx') || file.endsWith('.ts')) &&
               !file.endsWith('.test.ts') &&
               !file.endsWith('.test.tsx') &&
               !file.includes('vitest') &&
               !file.endsWith('.d.ts') &&
               !fullPath.includes('/vue/')) {
      // Create relative path from baseDir
      const baseResolved = resolve(baseDir);
      const relativePath = fullPath
        .replace(baseResolved + '/', '')
        .replace(/\.tsx?$/, '');
      entries[relativePath] = fullPath;
    }
  }

  return entries;
}

export default defineConfig({
  plugins: [react()],
  build: {
    lib: {
      entry: getEntryPoints('./priv/nb_inertia'),
      formats: ['es'],
    },
    rollupOptions: {
      external: [
        'react',
        'react/jsx-runtime',
        'react-dom',
        '@inertiajs/react',
        '@inertiajs/vue3',
        '@radix-ui/react-dialog',
        'radix-vue',
        'vue',
      ],
      output: {
        preserveModules: true,
        preserveModulesRoot: 'priv/nb_inertia',
        entryFileNames: '[name].js',
      },
    },
    outDir: 'dist',
    emptyOutDir: true,
  },
});
