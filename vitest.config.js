import { defineConfig } from 'vitest/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  esbuild: {
    include: /\.[jt]sx?$/,
    exclude: [],
    loader: 'tsx'
  },
  resolve: {
    alias: {
      '../src/data/rating-data-access': path.resolve(__dirname, 'src/data/rating-data-access.js'),
      './test-db-setup': path.resolve(__dirname, '__cyclone_tests__/test-db-setup.js')
    }
  },
  test: {
    include: ['__cyclone_tests__/**/*.test.js', '__cyclone_tests__/**/*.test.ts', '__cyclone_tests__/**/*.test.jsx'],
    exclude: ['__cyclone_tests__/test-db-setup.js', '__cyclone_tests__/edit-drink-form/edit-drink-form.jsx', '__cyclone_tests__/edit-drink-form/test_003_end-to-end_test__complete_edit_flow_from.test.js', '__cyclone_tests__/setup.js'],
    testTimeout: 30000,
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./__cyclone_tests__/setup.js']
  }
});
