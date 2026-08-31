import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vite-plus/test';

describe('schema-aware createInertiaApp bundle boundary', () => {
  it('keeps the schema implementation behind an opt-in dynamic import', () => {
    const source = readFileSync(resolve(process.cwd(), 'createInertiaApp.ts'), 'utf8');

    expect(source).toContain("await import('../shared/schemaRuntime')");
    expect(source).toContain('if (!appNeedsRuntime(options))');
    expect(source).not.toContain("import { createSchemaAwareInertiaApp } from '../shared/schemaRuntime'");
  });
});
