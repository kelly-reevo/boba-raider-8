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
      '../components/edit-store-form': path.resolve(__dirname, '__cyclone_tests__/components/edit-store-form.jsx')
    }
  },
  test: {
    include: [
      '__cyclone_tests__/rating-data-access/*',
      '__cyclone_tests__/edit-store-form/*.test.[jt]s',
      '__cyclone_tests__/edit-store-form/*.test.[jt]sx'
    ],
    exclude: [
      '__cyclone_tests__/test-db-setup.js',
      '__cyclone_tests__/test-setup.js',
      '__cyclone_tests__/edit-store-form/*e2e*'
    ],
    setupFiles: ['./__cyclone_tests__/test-setup.js'],
    testTimeout: 30000,
    environment: 'happy-dom',
    globals: true
  }
});
