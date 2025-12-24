// API endpoint base; override via VITE_API_BASE_URL for different environments
// 本地开发默认使用 localhost:8000，Docker/K8s 环境可通过环境变量覆盖
const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";

export async function searchArticles(query) {
  // Build a URL with query param and call the backend search endpoint.
  const url = new URL("/search", API_BASE);
  url.searchParams.set("q", query);
  const res = await fetch(url, { headers: { "Content-Type": "application/json" } });
  if (!res.ok) {
    throw new Error(`Search failed: ${res.statusText}`);
  }
  return res.json();
}

export async function createArticle(payload) {
  // POST a new article; payload should include title and content.
  const res = await fetch(`${API_BASE}/posts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`Create failed: ${res.statusText}`);
  }
  return res.json();
}

