import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  root: path.resolve(__dirname, '../..'),
  test: {
    environment: 'jsdom',
    include: ['__cyclone_tests__/error-feedback/**/*.js'],
    exclude: ['**/node_modules/**'],
    deps: {
      inline: true,
    },
  },
  resolve: {
    alias: {
      '../src/error-feedback.js': path.resolve(__dirname, '../../src/error-feedback.js'),
      '../src/api-client.js': path.resolve(__dirname, '../../src/api-client.js'),
    },
  },
  optimizeDeps: {
    include: ['vitest'],
  },
});
