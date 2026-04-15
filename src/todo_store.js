// In-memory todo store with proper state management
let storeState = {
  todos: [],
  currentFilter: 'all',
  changeListeners: [],
};

/**
 * Initialize the todo store
 * @returns {Object} Store API
 */
export function initTodoStore() {
  return {
    setTodos,
    getTodos,
    addTodo,
    deleteTodo,
    updateTodo,
    setFilter,
    getFilter,
    subscribe,
    notifyChange,
  };
}

/**
 * Set all todos (used for initialization)
 * @param {Array} newTodos
 */
export function setTodos(newTodos) {
  storeState.todos = [...newTodos];
  notifyChange();
}

/**
 * Get all todos
 * @returns {Array} Current todos (filtered based on currentFilter)
 */
export function getTodos() {
  if (storeState.currentFilter === 'all') {
    return [...storeState.todos];
  } else if (storeState.currentFilter === 'active') {
    return storeState.todos.filter(todo => !todo.completed);
  } else if (storeState.currentFilter === 'completed') {
    return storeState.todos.filter(todo => todo.completed);
  }
  return [...storeState.todos];
}

/**
 * Get raw todos without filter
 * @returns {Array} All todos
 */
export function getAllTodos() {
  return [...storeState.todos];
}

/**
 * Add a new todo
 * @param {Object} todo
 */
export function addTodo(todo) {
  storeState.todos.push(todo);
  notifyChange();
}

/**
 * Delete a todo by id
 * @param {string} id
 */
export function deleteTodo(id) {
  storeState.todos = storeState.todos.filter(todo => todo.id !== id);
  notifyChange();
}

/**
 * Update a todo
 * @param {string} id
 * @param {Object} updates
 */
export function updateTodo(id, updates) {
  storeState.todos = storeState.todos.map(todo => {
    if (todo.id === id) {
      return { ...todo, ...updates };
    }
    return todo;
  });
  notifyChange();
}

/**
 * Set the current filter
 * @param {string} filter - 'all', 'active', or 'completed'
 */
export function setFilter(filter) {
  storeState.currentFilter = filter;
  notifyChange();
}

/**
 * Get the current filter
 * @returns {string}
 */
export function getFilter() {
  return storeState.currentFilter;
}

/**
 * Subscribe to store changes
 * @param {Function} listener
 */
export function subscribe(listener) {
  storeState.changeListeners.push(listener);
  return () => {
    storeState.changeListeners = storeState.changeListeners.filter(l => l !== listener);
  };
}

/**
 * Notify all listeners of changes
 */
export function notifyChange() {
  // Create a copy of listeners to avoid issues if a listener modifies the array
  const listeners = [...storeState.changeListeners];
  listeners.forEach(listener => listener());
}
