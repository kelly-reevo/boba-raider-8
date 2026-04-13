import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    include: [
      'test/**/*_test.js',
      '../__cyclone_tests__/**/*.js'
    ],
    coverage: {
      reporter: ['text', 'html'],
    },
  },
});
