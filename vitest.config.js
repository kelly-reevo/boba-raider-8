import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  plugins: [
    react(),
    {
      name: 'treat-tests-as-jsx',
      enforce: 'pre',
      async transform(code, id) {
        if (id.includes('__cyclone_tests__/boba-rating-form/') && !id.includes('node_modules')) {
          // Return code as-is to let esbuild handle it with jsx loader
          return null;
        }
      }
    }
  ],
  esbuild: {
    loader: 'tsx',
    include: [
      /__cyclone_tests__\/boba-rating-form\/[^.]+$/,
      /src\/components\/.*\.jsx$/
    ]
  },
  resolve: {
    alias: {
      '../src/data/rating-data-access': path.resolve(__dirname, 'src/data/rating-data-access.js'),
      './test-db-setup': path.resolve(__dirname, '__cyclone_tests__/test-db-setup.js'),
      './BobaRatingForm': path.resolve(__dirname, 'src/components/BobaRatingForm.jsx')
    }
  },
  test: {
    include: ['__cyclone_tests__/rating-data-access/*', '__cyclone_tests__/boba-rating-form/*'],
    exclude: ['__cyclone_tests__/test-db-setup.js', '__cyclone_tests__/setup.js'],
    testTimeout: 30000,
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./__cyclone_tests__/setup.js']
  }
});
