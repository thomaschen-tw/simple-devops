/**
 * API 调用封装
 * 统一管理前后端 API 通信
 */

// API 基础地址；可通过环境变量 VITE_API_BASE_URL 覆盖（用于不同环境）
// 本地开发默认使用 localhost:8000，Docker/K8s 环境可通过环境变量覆盖
const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";

/**
 * 搜索文章
 * 调用后端搜索接口，根据关键词搜索文章标题和内容
 * 
 * @param {string} query - 搜索关键词
 * @returns {Promise<Array>} 匹配的文章列表
 * @throws {Error} 当请求失败时抛出错误
 */
export async function searchArticles(query) {
  // 构建带查询参数的 URL 并调用后端搜索接口
  const url = new URL("/search", API_BASE);
  url.searchParams.set("q", query);
  const res = await fetch(url, { headers: { "Content-Type": "application/json" } });
  if (!res.ok) {
    throw new Error(`搜索失败: ${res.statusText}`);
  }
  return res.json();
}

/**
 * 创建文章
 * 调用后端创建接口，创建一篇新文章
 * 
 * @param {Object} payload - 文章数据对象，包含 title 和 content
 * @param {string} payload.title - 文章标题
 * @param {string} payload.content - 文章内容
 * @returns {Promise<Object>} 创建的文章对象（包含 id 和 created_at）
 * @throws {Error} 当请求失败时抛出错误
 */
export async function createArticle(payload) {
  // POST 请求创建新文章；payload 应包含 title 和 content
  const res = await fetch(`${API_BASE}/posts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`创建失败: ${res.statusText}`);
  }
  return res.json();
}
