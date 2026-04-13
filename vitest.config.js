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
      '../components/edit-store-form': path.resolve(__dirname, '__cyclone_tests__/components/edit-store-form.jsx'),
      '../src/components/create_drink_form_component': path.resolve(__dirname, 'src/components/create_drink_form_component.js'),
      './BobaRatingForm': path.resolve(__dirname, 'src/components/BobaRatingForm.jsx')
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
      '__cyclone_tests__/edit-drink-form/*.test.jsx',
      '__cyclone_tests__/boba-rating-form/*',
      '__cyclone_tests__/store-search-component/*'
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
