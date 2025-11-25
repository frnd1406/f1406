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
