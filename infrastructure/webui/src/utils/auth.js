export function getAuth() {
  return {
    accessToken: localStorage.getItem("access_token") || "",
    csrfToken: localStorage.getItem("csrf_token") || "",
  };
}

export function authHeaders() {
  const { accessToken, csrfToken } = getAuth();
  const headers = {};
  if (accessToken) headers["Authorization"] = `Bearer ${accessToken}`;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  return headers;
}

export function setAuth({ accessToken = "", refreshToken = "", csrfToken = "" }) {
  if (accessToken) localStorage.setItem("access_token", accessToken);
  if (refreshToken) localStorage.setItem("refresh_token", refreshToken);
  if (csrfToken) localStorage.setItem("csrf_token", csrfToken);
}

export function clearAuth() {
  localStorage.removeItem("access_token");
  localStorage.removeItem("refresh_token");
  localStorage.removeItem("csrf_token");
}

export function isAuthenticated() {
  const { accessToken } = getAuth();
  return Boolean(accessToken);
}
