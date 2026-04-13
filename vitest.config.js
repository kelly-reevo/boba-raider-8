import { defineConfig } from 'vitest/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  esbuild: {
    jsx: 'automatic',
    jsxImportSource: 'react'
  },
  resolve: {
    alias: {
      '../src/data/rating-data-access': path.resolve(__dirname, 'src/data/rating-data-access.js'),
      './test-db-setup': path.resolve(__dirname, '__cyclone_tests__/test-db-setup.js'),
      '../components/edit-store-form': path.resolve(__dirname, '__cyclone_tests__/components/edit-store-form.jsx'),
      '../src/components/create_drink_form_component': path.resolve(__dirname, 'src/components/create_drink_form_component.js')
    }
  },
  test: {
    include: [
      '__cyclone_tests__/rating-data-access/*',
      '__cyclone_tests__/edit-store-form/*.test.[jt]s',
      '__cyclone_tests__/edit-store-form/*.test.[jt]sx',
      '__cyclone_tests__/create-drink-form/*',
      '__cyclone_tests__/edit-drink-form/*.test.js',
      '__cyclone_tests__/edit-drink-form/*.test.ts',
      '__cyclone_tests__/edit-drink-form/*.test.jsx'
    ],
    exclude: [
      '__cyclone_tests__/test-db-setup.js',
      '__cyclone_tests__/test-setup.js',
      '__cyclone_tests__/edit-store-form/*e2e*',
      '__cyclone_tests__/edit-drink-form/edit-drink-form.jsx',
      '__cyclone_tests__/edit-drink-form/test_003_end-to-end_test__complete_edit_flow_from.test.js',
      '__cyclone_tests__/setup.js'
    ],
    setupFiles: ['./__cyclone_tests__/test-setup.js'],
    testTimeout: 30000,
    environment: 'jsdom',
    globals: true
  }
});
