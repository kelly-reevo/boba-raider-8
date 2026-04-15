import { defineConfig } from 'vitest/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  test: {
    environment: 'jsdom',
    include: ['__cyclone_tests__/**/*.js', '__cyclone_tests__/**/*'],
    exclude: ['node_modules', 'dist', '.idea', '.git', '.cache'],
    globals: true,
    setupFiles: [],
  },
  resolve: {
    alias: [
      {
        find: /\.\.\/src\/(.*)$/,
        replacement: path.resolve(__dirname, './src/$1'),
      },
    ],
  },
});
