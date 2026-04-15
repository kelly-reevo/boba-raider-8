import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['test/**/*_test.js', 'test/**/*.test.js'],
  },
});
