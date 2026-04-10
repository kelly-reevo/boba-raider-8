/// Client-side FFI for localStorage and API calls

import { Ok, Error } from "./gleam.mjs";
import { User, AuthToken, AuthResponse, InvalidInput, InternalError, Unauthorized } from "../shared/src/shared.gleam";

const STORAGE_KEY = "boba_raider_auth";

/**
 * Load authentication data from localStorage
 * @returns {Result} - Ok(#(User, AuthToken)) or Error(String)
 */
export function loadAuthFromStorage() {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (!stored) {
      return new Error("No stored auth data");
    }

    const data = JSON.parse(stored);

    // Validate required fields
    if (!data.user || !data.token) {
      return new Error("Invalid stored data format");
    }

    const user = new User(data.user.id, data.user.username, data.user.email);
    const token = new AuthToken(data.token.access_token, data.token.refresh_token);

    return new Ok([user, token]);
  } catch (err) {
    return new Error("Failed to parse stored auth data: " + err.message);
  }
}

/**
 * Save authentication data to localStorage
 * @param {User} user - The user object
 * @param {AuthToken} token - The auth token object
 * @returns {boolean} - True if saved successfully
 */
export function saveAuthToStorage(user, token) {
  try {
    const data = {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
      },
      token: {
        access_token: token.access_token,
        refresh_token: token.refresh_token,
      },
    };

    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    return true;
  } catch (err) {
    console.error("Failed to save auth to localStorage:", err);
    return false;
  }
}

/**
 * Clear authentication data from localStorage
 */
export function clearAuthFromStorage() {
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch (err) {
    console.error("Failed to clear auth from localStorage:", err);
  }
}

/**
 * Perform login API call
 * In production, replace this with actual fetch/HTTP request
 * @param {string} email
 * @param {string} password
 * @returns {Promise<Result<AuthResponse, AppError>>}
 */
export function loginApiCall(email, password) {
  return new Promise((resolve) => {
    // Simulate API delay
    setTimeout(() => {
      // Demo: accept any non-empty password >= 8 chars
      if (!email || !password || password.length < 8) {
        resolve(new Error(new InvalidInput("Invalid credentials")));
        return;
      }

      // Generate a mock response
      const userId = "user_" + Math.random().toString(36).substr(2, 9);
      const user = new User(userId, email.split("@")[0], email);
      const token = new AuthToken(
        "access_" + Math.random().toString(36).substr(2, 16),
        "refresh_" + Math.random().toString(36).substr(2, 16)
      );

      resolve(new Ok(new AuthResponse(user, token)));
    }, 800); // Simulate network delay
  });
}

/**
 * Perform registration API call
 * In production, replace this with actual fetch/HTTP request
 * @param {string} username
 * @param {string} email
 * @param {string} password
 * @returns {Promise<Result<AuthResponse, AppError>>}
 */
export function registerApiCall(username, email, password) {
  return new Promise((resolve) => {
    // Simulate API delay
    setTimeout(() => {
      // Demo: accept any valid-looking input
      if (!username || username.length < 3) {
        resolve(new Error(new InvalidInput("Username must be at least 3 characters")));
        return;
      }

      if (!email || !email.includes("@")) {
        resolve(new Error(new InvalidInput("Please provide a valid email")));
        return;
      }

      if (!password || password.length < 8) {
        resolve(new Error(new InvalidInput("Password must be at least 8 characters")));
        return;
      }

      // Generate a mock response
      const userId = "user_" + Math.random().toString(36).substr(2, 9);
      const user = new User(userId, username, email);
      const token = new AuthToken(
        "access_" + Math.random().toString(36).substr(2, 16),
        "refresh_" + Math.random().toString(36).substr(2, 16)
      );

      resolve(new Ok(new AuthResponse(user, token)));
    }, 1000); // Simulate network delay
  });
}
