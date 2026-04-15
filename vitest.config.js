import { defineConfig } from 'vitest/config';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    include: ['__cyclone_tests__/**/*'],
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
