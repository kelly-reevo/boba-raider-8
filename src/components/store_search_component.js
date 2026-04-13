/**
 * Store Search Component
 * Provides debounced search input for filtering stores by name or city
 * Boundary contract: Produces GET /api/stores?search=string&limit=10 -> Updates StoreList display
 */

/**
 * Renders store list to DOM without page reload
 * Handles populated state, empty state, and restore full list
 */
export class StoreListRenderer {
  constructor(containerId, initialStores = []) {
    this.container = document.getElementById(containerId);
    this.allStores = initialStores;
  }

  /**
   * Update the full store list reference
   * @param {Array} stores - All available stores
   */
  setAllStores(stores) {
    this.allStores = stores;
  }

  /**
   * Render stores to the container
   * @param {Array} stores - Stores to render (empty array restores full list)
   */
  renderStores(stores) {
    if (!this.container) return;

    this.container.innerHTML = '';

    if (stores.length === 0 && this.allStores.length > 0) {
      this.renderAllStores();
      return;
    }

    if (stores.length === 0) {
      this.renderEmptyState();
      return;
    }

    stores.forEach(store => this.createStoreElement(store));
  }

  /**
   * Render all stores (when search is cleared)
   */
  renderAllStores() {
    this.allStores.forEach(store => this.createStoreElement(store));
  }

  /**
   * Create a single store element
   * @param {Object} store - Store with id, name, city
   */
  createStoreElement(store) {
    const storeEl = document.createElement('div');
    storeEl.className = 'store-item';
    storeEl.setAttribute('data-id', store.id);

    const nameEl = document.createElement('span');
    nameEl.className = 'store-name';
    nameEl.textContent = store.name;
    storeEl.appendChild(nameEl);

    if (store.city) {
      const cityEl = document.createElement('span');
      cityEl.className = 'store-city';
      cityEl.textContent = store.city;
      storeEl.appendChild(cityEl);
    }

    this.container.appendChild(storeEl);
  }

  /**
   * Render empty state message
   */
  renderEmptyState() {
    const emptyEl = document.createElement('div');
    emptyEl.className = 'no-results-message';
    emptyEl.textContent = 'No stores found';
    this.container.appendChild(emptyEl);
  }
}

/**
 * Store Search Component
 * Wires up search input with debounced API calls and result rendering
 */
export class StoreSearchComponent {
  /**
   * @param {string} searchInputId - ID of the search input element
   * @param {string} storeListContainerId - ID of the container for store results
   * @param {Array} allStores - Initial full store list for restore on clear
   */
  constructor(searchInputId, storeListContainerId, allStores = []) {
    this.searchInput = document.getElementById(searchInputId);
    this.renderer = new StoreListRenderer(storeListContainerId, allStores);
    this.allStores = allStores;
    this.debounceTimer = null;
    this.debounceDelay = 300;
    this.lastQuery = '';

    if (this.searchInput) {
      this.searchInput.addEventListener('input', (e) => this.handleInput(e.target.value));
    }
  }

  /**
   * Handle input changes with debouncing
   * @param {string} value - Current input value
   */
  handleInput(value) {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.executeSearch(value);
    }, this.debounceDelay);
  }

  /**
   * Execute search query
   * @param {string} query - Search query
   */
  async executeSearch(query) {
    const trimmedQuery = query.trim();
    this.lastQuery = trimmedQuery;

    if (!trimmedQuery) {
      this.renderer.renderStores([]);
      return;
    }

    try {
      const response = await fetch(`/api/stores?search=${encodeURIComponent(trimmedQuery)}&limit=10`);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      const stores = await response.json();
      this.renderer.renderStores(stores);
    } catch (error) {
      this.renderer.renderStores([]);
    }
  }

  /**
   * Clean up timers and event listeners
   */
  destroy() {
    clearTimeout(this.debounceTimer);
  }
}
