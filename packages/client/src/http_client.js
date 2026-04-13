// HTTP Client for making fetch calls to backend API endpoints
// Provides methods for GET, POST, PATCH, DELETE with proper headers and JSON handling

export class HttpClient {
  constructor(baseUrl = '') {
    this.baseUrl = baseUrl;
  }

  // GET request with optional query params
  async get(url, params = {}) {
    const queryString = new URLSearchParams(params).toString();
    const fullUrl = queryString
      ? `${this.baseUrl}${url}?${queryString}`
      : `${this.baseUrl}${url}`;

    const response = await fetch(fullUrl, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    });

    return this._handleResponse(response);
  }

  // POST request with JSON body
  async post(url, body) {
    const response = await fetch(`${this.baseUrl}${url}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(body)
    });

    return this._handleResponse(response);
  }

  // PATCH request with JSON body for partial updates
  async patch(url, body) {
    const response = await fetch(`${this.baseUrl}${url}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(body)
    });

    return this._handleResponse(response);
  }

  // DELETE request
  async delete(url) {
    const response = await fetch(`${this.baseUrl}${url}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json'
      }
    });

    return this._handleResponse(response);
  }

  // Handle response: parse JSON on success, throw error on failure
  async _handleResponse(response) {
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw {
        status: response.status,
        message: errorData.message || `HTTP ${response.status}: ${response.statusText}`,
        errors: errorData.errors || {}
      };
    }

    // Handle 204 No Content responses (e.g., successful DELETE)
    if (response.status === 204) {
      return null;
    }

    return response.json();
  }
}

// Default export for convenience
export default HttpClient;
