import { defineConfig } from 'vitest/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  resolve: {
    alias: {
      '../src/data/rating-data-access': path.resolve(__dirname, 'src/data/rating-data-access.js'),
      './test-db-setup': path.resolve(__dirname, '__cyclone_tests__/test-db-setup.js')
    }
  },
  test: {
    include: ['__cyclone_tests__/**/*.test.js'],
    exclude: ['__cyclone_tests__/test-db-setup.js', '__cyclone_tests__/test-setup.js'],
    testTimeout: 30000,
    environment: 'jsdom',
    setupFiles: ['./__cyclone_tests__/test-setup.js']
  }
});
