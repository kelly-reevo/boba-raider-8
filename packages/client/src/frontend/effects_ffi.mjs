// FFI module for synchronous HTTP requests using fetch API

export function fetchSync(req) {
  const url = req.path;
  const method = req.method || "GET";
  const headers = req.headers || [];
  const body = req.body || null;

  // Convert Gleam headers array to object
  const headerObj = {};
  for (const [name, value] of headers) {
    headerObj[name] = value;
  }

  const fetchOptions = {
    method,
    headers: headerObj,
  };

  if (body && method !== "GET" && method !== "HEAD") {
    fetchOptions.body = body;
  }

  try {
    // Use synchronous XMLHttpRequest for effect compatibility
    const xhr = new XMLHttpRequest();
    xhr.open(method, url, false); // false = synchronous

    for (const [name, value] of headers) {
      xhr.setRequestHeader(name, value);
    }

    xhr.send(body);

    if (xhr.status >= 200 && xhr.status < 300) {
      return { Ok: xhr.responseText };
    } else if (xhr.status >= 400) {
      return { Error: `HTTP ${xhr.status}: ${xhr.statusText}` };
    } else {
      return { Ok: xhr.responseText };
    }
  } catch (error) {
    return { Error: error.message || "Network error" };
  }
}
