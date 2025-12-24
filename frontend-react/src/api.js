/**
 * API 调用封装
 * 统一管理前后端 API 通信
 */

// API 基础地址配置
// 优先使用环境变量，如果没有则根据当前环境自动判断
// - 开发环境：使用 localhost:8000
// - 生产环境（AWS ALB）：使用相对路径（通过 ALB 路径路由）
const getApiBase = () => {
  // 如果设置了环境变量，直接使用
  if (import.meta.env.VITE_API_BASE_URL) {
    return import.meta.env.VITE_API_BASE_URL;
  }
  
  // 生产环境：使用相对路径（通过 ALB 路径路由）
  // ALB 会将 /search、/posts 等路径转发到后端
  if (window.location.hostname !== "localhost" && window.location.hostname !== "127.0.0.1") {
    return ""; // 使用相对路径
  }
  
  // 开发环境：使用 localhost
  return "http://localhost:8000";
};

const API_BASE = getApiBase();

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
  // 如果 API_BASE 为空，使用相对路径
  const baseUrl = API_BASE || window.location.origin;
  const url = new URL("/search", baseUrl);
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
  // 如果 API_BASE 为空，使用相对路径
  const baseUrl = API_BASE || window.location.origin;
  const res = await fetch(`${baseUrl}/posts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`创建失败: ${res.statusText}`);
  }
  return res.json();
}

/**
 * 获取文章详情
 * 根据文章 ID 获取单篇文章的详细信息
 * 
 * @param {number} articleId - 文章 ID
 * @returns {Promise<Object>} 文章详情对象（包含 id、title、content 和 created_at）
 * @throws {Error} 当请求失败或文章不存在时抛出错误
 */
export async function getArticle(articleId) {
  // 如果 API_BASE 为空，使用相对路径
  const baseUrl = API_BASE || window.location.origin;
  const res = await fetch(`${baseUrl}/posts/${articleId}`, {
    headers: { "Content-Type": "application/json" },
  });
  if (!res.ok) {
    if (res.status === 404) {
      throw new Error("文章不存在");
    }
    throw new Error(`获取文章失败: ${res.statusText}`);
  }
  return res.json();
}
