import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./test-setup.js'],
    include: [
      'packages/frontend/test/**/*.test.js'
    ],
    exclude: [
      '**/test_*e2e*.test.js'
    ],
    testTimeout: 10000
  }
});
