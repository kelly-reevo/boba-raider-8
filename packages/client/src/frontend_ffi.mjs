/// FFI module for JavaScript fetch API integration
/// Handles all HTTP requests for the todo application

/**
 * Fetch all todos from the API
 * @param {Function} dispatch - Function to dispatch messages back to Gleam
 */
export function fetchTodos(dispatch) {
  fetch('/api/todos')
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to fetch todos');
      }
      return response.json();
    })
    .then(todos => {
      // Convert JSON todos to Gleam format
      const gleamTodos = todos.map(todo => ({
        id: todo.id,
        title: todo.title,
        description: todo.description === null ? undefined : todo.description,
        priority: parsePriority(todo.priority),
        completed: todo.completed,
        created_at: todo.created_at,
        updated_at: todo.updated_at,
      }));
      dispatch({ type: 'TodosLoaded', todos: gleamTodos });
    })
    .catch(error => {
      dispatch({ type: 'TodosLoadFailed', error: error.message });
    });
}

/**
 * Create a new todo via API
 * @param {string} title - Todo title
 * @param {string|undefined} description - Todo description (optional)
 * @param {Function} dispatch - Function to dispatch messages back to Gleam
 */
export function createTodo(title, description, dispatch) {
  const body = {
    title: title,
    description: description === undefined ? null : description,
    priority: 'medium',
    completed: false,
  };

  fetch('/api/todos', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to create todo');
      }
      return response.json();
    })
    .then(todo => {
      const gleamTodo = {
        id: todo.id,
        title: todo.title,
        description: todo.description === null ? undefined : todo.description,
        priority: parsePriority(todo.priority),
        completed: todo.completed,
        created_at: todo.created_at,
        updated_at: todo.updated_at,
      };
      dispatch({ type: 'TodoCreated', todo: gleamTodo });
    })
    .catch(error => {
      dispatch({ type: 'TodoCreateFailed', error: error.message });
    });
}

/**
 * Update a todo via API
 * @param {string} id - Todo ID
 * @param {string} title - Todo title
 * @param {string|undefined} description - Todo description
 * @param {Object} priority - Priority object from Gleam
 * @param {boolean} completed - Completion status
 * @param {Function} dispatch - Function to dispatch messages back to Gleam
 */
export function updateTodo(id, title, description, priority, completed, dispatch) {
  const body = {
    title: title,
    description: description === undefined ? null : description,
    priority: priorityToString(priority),
    completed: completed,
  };

  fetch(`/api/todos/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to update todo');
      }
      return response.json();
    })
    .then(todo => {
      const gleamTodo = {
        id: todo.id,
        title: todo.title,
        description: todo.description === null ? undefined : todo.description,
        priority: parsePriority(todo.priority),
        completed: todo.completed,
        created_at: todo.created_at,
        updated_at: todo.updated_at,
      };
      dispatch({ type: 'TodoUpdated', todo: gleamTodo });
    })
    .catch(error => {
      dispatch({ type: 'TodoUpdateFailed', error: error.message });
    });
}

/**
 * Delete a todo via API
 * @param {string} id - Todo ID
 * @param {Function} dispatch - Function to dispatch messages back to Gleam
 */
export function deleteTodo(id, dispatch) {
  fetch(`/api/todos/${id}`, {
    method: 'DELETE',
  })
    .then(response => {
      if (!response.ok) {
        throw new Error('Failed to delete todo');
      }
      dispatch({ type: 'TodoDeleted', id: id });
    })
    .catch(error => {
      dispatch({ type: 'TodoDeleteFailed', error: error.message });
    });
}

/**
 * Parse priority string to Gleam priority variant
 * @param {string} priorityStr - Priority string from API
 * @returns {Object} Gleam priority variant
 */
function parsePriority(priorityStr) {
  switch (priorityStr.toLowerCase()) {
    case 'low':
      return { constructor: 'Low', values: [] };
    case 'high':
      return { constructor: 'High', values: [] };
    case 'medium':
    default:
      return { constructor: 'Medium', values: [] };
  }
}

/**
 * Convert Gleam priority variant to string
 * @param {Object} priority - Gleam priority variant
 * @returns {string} Priority string for API
 */
function priorityToString(priority) {
  // Handle both new and old format
  if (typeof priority === 'string') {
    return priority.toLowerCase();
  }
  if (priority && priority.constructor) {
    return priority.constructor.toLowerCase();
  }
  return 'medium';
}
