import { defineConfig, lazyPlugins } from 'vite-plus';
import react from '@vitejs/plugin-react';
import dts from 'vite-plugin-dts';
import { resolve } from 'path';
import { mkdirSync, readdirSync, statSync, writeFileSync } from 'fs';

// Recursively find all .tsx and .ts files to use as entry points
function getEntryPoints(dir, baseDir = null) {
  if (!baseDir) baseDir = dir;
  const entries = {};
  const files = readdirSync(dir);

  for (const file of files) {
    const fullPath = resolve(dir, file);
    const stat = statSync(fullPath);

    if (stat.isDirectory()) {
      if (['node_modules', 'coverage', '__tests__'].includes(file)) {
        continue;
      }
      Object.assign(entries, getEntryPoints(fullPath, baseDir));
    } else if (
      (file.endsWith('.tsx') || file.endsWith('.ts')) &&
      !file.endsWith('.test.ts') &&
      !file.endsWith('.test.tsx') &&
      !file.endsWith('.typecheck.ts') &&
      !file.includes('vitest') &&
      !file.includes('vite.config') &&
      !file.endsWith('.d.ts') &&
      !fullPath.includes('/node_modules/') &&
      !fullPath.includes('/vue/')
    ) {
      // Create relative path from baseDir
      const baseResolved = resolve(baseDir);
      const relativePath = fullPath.replace(baseResolved + '/', '').replace(/\.tsx?$/, '');
      entries[relativePath] = fullPath;
    }
  }

  return entries;
}

// Vue source files are intentionally excluded from the recursive scan because
// the modal entrypoint imports .vue SFCs. These thin adapter re-exports only
// import official JavaScript packages, so add them explicitly as build
// entries while keeping the SFC source out of the package build.
function getOfficialVueEntryPoints() {
  const entryNames = [
    'index',
    'server',
    'Deferred',
    'Form',
    'InfiniteScroll',
    'WhenVisible',
    'usePoll',
    'usePrefetch',
    'useRemember',
  ];

  return Object.fromEntries(
    entryNames.map((entryName) => [
      `vue/${entryName}`,
      resolve(`./priv/nb_inertia/vue/${entryName}.ts`),
    ]),
  );
}

function emitVueModalRuntimeEntry() {
  return {
    name: 'emit-vue-modal-runtime-entry',
    writeBundle() {
      const outputDir = resolve('dist/vue/modals');
      mkdirSync(outputDir, { recursive: true });
      writeFileSync(
        resolve(outputDir, 'index.js'),
        [
          '// Runtime entry for Vue modal components.',
          '// Consumers use this via their bundler (Vite + @vitejs/plugin-vue),',
          '// which handles the downstream .vue SFC imports natively.',
          '// TypeScript consumers use the "types" condition -> index.d.ts instead.',
          "export * from '../../../priv/nb_inertia/vue/modals/index.ts';",
          '',
        ].join('\n'),
      );
    },
  };
}

export default defineConfig({
  // Force production JSX transform: use jsx-runtime (not jsx-dev-runtime), no fileName/lineNumber metadata
  oxc: {
    jsx: {
      development: false,
    },
  },
  // Vite+ reads this config for `vp check` and editor metadata. Keep framework
  // plugins out of that path; they are only instantiated for actual Vite work.
  plugins: lazyPlugins(() => [
    react(),
    emitVueModalRuntimeEntry(),
    dts({
      include: ['priv/nb_inertia/**/*.{ts,tsx}'],
      exclude: [
        '**/*.test.ts',
        '**/*.test.tsx',
        '**/*.typecheck.ts',
        '**/vitest.*',
        '**/vue/**',
        '**/node_modules/**',
      ],
      outDir: 'dist',
      rollupTypes: true,
    }),
  ]),
  fmt: {
    ignorePatterns: ['dist/**', 'priv/components/**', '**/node_modules/**', '**/coverage/**'],
    singleQuote: true,
    semi: true,
  },
  lint: {
    ignorePatterns: ['dist/**', 'priv/components/**', '**/node_modules/**', '**/coverage/**'],
    options: {
      typeAware: true,
      typeCheck: true,
    },
    overrides: [
      {
        // These tests intentionally inspect Vitest mocks by reference; the
        // methods are mock functions and do not depend on a receiver.
        files: ['priv/nb_inertia/**/*.test.ts', 'priv/nb_inertia/**/*.test.tsx'],
        rules: {
          'typescript/unbound-method': 'off',
        },
      },
      {
        // The enhanced router deliberately copies Inertia's public methods so
        // consumers can continue using the complete router surface.
        files: ['priv/nb_inertia/react/router.ts'],
        rules: {
          'typescript/no-misused-spread': 'off',
        },
      },
    ],
  },
  // The package predates Vite+ and intentionally keeps its existing source
  // formatting. Keep formatting available via the standalone `fmt` command,
  // while making the default check enforce linting and TypeScript correctness.
  check: {
    fmt: false,
  },
  build: {
    lib: {
      entry: {
        ...getEntryPoints('./priv/nb_inertia'),
        ...getOfficialVueEntryPoints(),
      },
      formats: ['es'],
    },
    rollupOptions: {
      external: [
        'react',
        'react/jsx-runtime',
        'react/jsx-dev-runtime',
        'react-dom',
        '@inertiajs/core',
        '@inertiajs/react',
        '@inertiajs/react/server',
        '@inertiajs/vue3',
        '@inertiajs/vue3/server',
        'laravel-precognition',
        '@radix-ui/react-dialog',
        'radix-vue',
        'vue',
        'phoenix',
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
