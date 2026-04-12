import { defineConfig } from 'vitest/config';
import path from 'path';

// Work around vitest hoisting issues in test files
const mockHoistPlugin = () => ({
  name: 'mock-hoist-fix',
  enforce: 'pre',
  transform(code, id) {
    if (!id.includes('__cyclone_tests__')) return;

    // Fix the hoisting issue by:
    // 1. Moving the vi.mock factory to not reference external variables
    // 2. Re-importing the mocked function after vi.mock to get the actual mock reference

    // Check if this file has both mocks (test_001 style)
    const hasBothMocks = code.includes('const createTodoMock = vi.fn()') &&
                         code.includes('const refreshListMock = vi.fn()') &&
                         code.includes("vi.mock('../api-client.js'") &&
                         code.includes("vi.mock('../todo-list.js'");

    if (hasBothMocks) {
      // Handle files with both mocks (test_001 style)
      code = code.replace(
        /const createTodoMock = vi\.fn\(\);\s*const refreshListMock = vi\.fn\(\);\s*vi\.mock\(['"]\.\.\/api-client\.js['"],\s*\(\) => \(\{\s*createTodo: createTodoMock\s*\}\)\);?\s*vi\.mock\(['"]\.\.\/todo-list\.js['"],\s*\(\) => \(\{\s*refreshTodoList: refreshListMock\s*\}\)\);?/,
        `vi.mock('../api-client.js', () => {
  const mock = vi.fn();
  return { createTodo: mock };
});
vi.mock('../todo-list.js', () => {
  const mock = vi.fn();
  return { refreshTodoList: mock };
});`
      );
      // Add re-imports after the main import
      const importMatch = code.match(/import\s+{\s*setupAddTodoForm\s*}\s+from\s+['"]\.\.\/add-todo-form\.js['"];?/);
      if (importMatch && !code.includes('// Mock imports added')) {
        code = code.replace(
          importMatch[0],
          `${importMatch[0]}\nimport { createTodo } from '../api-client.js';\nimport { refreshTodoList } from '../todo-list.js';\nconst createTodoMock = vi.mocked(createTodo);\nconst refreshListMock = vi.mocked(refreshTodoList);\n// Mock imports added`
        );
      }
    } else {
      // Fix api-client mock only
      if (code.includes('const createTodoMock = vi.fn()') && code.includes("vi.mock('../api-client.js'")) {
        code = code.replace(
          /const createTodoMock = vi\.fn\(\);\s*vi\.mock\(['"]\.\.\/api-client\.js['"],\s*\(\) => \(\{\s*createTodo: createTodoMock\s*\}\)\);?/,
          `vi.mock('../api-client.js', () => {
  const mock = vi.fn();
  return { createTodo: mock };
});`
        );
        // Add re-import after vi.mock to get the mock reference
        const importMatch = code.match(/import\s+{\s*setupAddTodoForm\s*}\s+from\s+['"]\.\.\/add-todo-form\.js['"];?/);
        if (importMatch && !code.includes('// Mock imports added')) {
          code = code.replace(
            importMatch[0],
            `${importMatch[0]}\nimport { createTodo } from '../api-client.js';\nconst createTodoMock = vi.mocked(createTodo);\n// Mock imports added`
          );
        }
      }

      // Fix todo-list mock only
      if (code.includes('const refreshListMock = vi.fn()') && code.includes("vi.mock('../todo-list.js'")) {
        code = code.replace(
          /const refreshListMock = vi\.fn\(\);\s*vi\.mock\(['"]\.\.\/todo-list\.js['"],\s*\(\) => \(\{\s*refreshTodoList: refreshListMock\s*\}\)\);?/,
          `vi.mock('../todo-list.js', () => {
  const mock = vi.fn();
  return { refreshTodoList: mock };
});`
        );
        // Add re-import after vi.mock
        const importMatch = code.match(/import\s+{\s*setupAddTodoForm\s*}\s+from\s+['"]\.\.\/add-todo-form\.js['"];?/);
        if (importMatch && !code.includes('// Mock imports added')) {
          code = code.replace(
            importMatch[0],
            `${importMatch[0]}\nimport { refreshTodoList } from '../todo-list.js';\nconst refreshListMock = vi.mocked(refreshTodoList);\n// Mock imports added`
          );
        }
      }
    }

    return code;
  },
});

export default defineConfig({
  plugins: [mockHoistPlugin()],
  test: {
    environment: 'jsdom',
    include: ['__cyclone_tests__/**/*'],
    globals: true,
  },
  resolve: {
    alias: {
      '../add-todo-form.js': path.resolve(__dirname, './add-todo-form.js'),
      '../api-client.js': path.resolve(__dirname, './api-client.js'),
      '../todo-list.js': path.resolve(__dirname, './todo-list.js'),
    },
  },
});
