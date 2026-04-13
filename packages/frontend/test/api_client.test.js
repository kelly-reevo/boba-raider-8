/**
 * Unit Tests for API Client
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';

const importClient = async () => {
  const modulePath = '../src/api_client.js';
  return await import(modulePath + '?t=' + Date.now());
};

describe('api_client', () => {
  let fetchMock;
  let client;

  beforeEach(async () => {
    fetchMock = vi.fn();
    global.fetch = fetchMock;
    client = await importClient();
  });

  describe('deleteTodo', () => {
    it('calls fetch with DELETE method and correct URL', async () => {
      const todoId = 'todo-123';
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 204
      });

      await client.deleteTodo(todoId);

      expect(fetchMock).toHaveBeenCalledWith(`/api/todos/${todoId}`, {
        method: 'DELETE'
      });
    });

    it('throws error when response is not ok (404)', async () => {
      const todoId = 'todo-not-found';
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 404,
        statusText: 'Not Found'
      });

      await expect(client.deleteTodo(todoId)).rejects.toThrow();
    });

    it('throws error when response is not ok (500)', async () => {
      const todoId = 'todo-123';
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error'
      });

      await expect(client.deleteTodo(todoId)).rejects.toThrow();
    });

    it('throws error for missing ID', async () => {
      await expect(client.deleteTodo('')).rejects.toThrow('Todo ID is required');
    });
  });

  describe('getAllTodos', () => {
    it('calls fetch with GET method', async () => {
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => []
      });

      await client.getAllTodos();

      expect(fetchMock).toHaveBeenCalledWith('/api/todos', {
        method: 'GET'
      });
    });

    it('returns parsed JSON response', async () => {
      const todos = [{ id: '1', title: 'Test' }];
      fetchMock.mockResolvedValueOnce({
        ok: true,
        status: 200,
        json: async () => todos
      });

      const result = await client.getAllTodos();

      expect(result).toEqual(todos);
    });

    it('throws error when response is not ok', async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Server Error'
      });

      await expect(client.getAllTodos()).rejects.toThrow();
    });
  });
});
