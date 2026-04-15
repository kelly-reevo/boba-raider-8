import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['__cyclone_tests__/**/*.js', '__cyclone_tests__/**/*'],
    exclude: ['node_modules', 'dist', '.idea', '.git', '.cache'],
    globals: true,
    setupFiles: [],
  },
});
