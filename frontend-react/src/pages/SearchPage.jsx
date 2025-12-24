/**
 * 搜索页面组件
 * 提供文章搜索功能，显示搜索结果列表
 */
import { useState } from "react";
import { searchArticles } from "../api";

/**
 * SearchPage 组件
 * 提供搜索功能，点击文章可跳转到详情页
 * 
 * @param {Object} props - 组件属性
 * @param {Function} props.onArticleClick - 文章点击回调函数，接收文章 ID
 * @returns {JSX.Element} 搜索页面组件
 */
function SearchPage({ onArticleClick }) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  /**
   * 处理搜索表单提交
   * 调用后端搜索接口，获取匹配的文章列表
   * 
   * @param {Event} event - 表单提交事件
   */
  const handleSearch = async (event) => {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      // 从后端获取搜索结果；后端使用 ILIKE 在标题和内容中搜索
      const data = await searchArticles(query);
      setResults(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  /**
   * 格式化日期时间为24小时制
   * 
   * @param {string} dateString - ISO 日期字符串
   * @returns {string} 格式化后的日期时间字符串（24小时制）
   */
  const formatDateTime = (dateString) => {
    const date = new Date(dateString);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hours = String(date.getHours()).padStart(2, "0");
    const minutes = String(date.getMinutes()).padStart(2, "0");
    const seconds = String(date.getSeconds()).padStart(2, "0");
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  };

  /**
   * 处理文章点击事件
   * 
   * @param {number} articleId - 文章 ID
   */
  const handleArticleClick = (articleId) => {
    if (onArticleClick) {
      onArticleClick(articleId);
    }
  };

  return (
    <section className="card">
      <h2>搜索文章</h2>
      <form onSubmit={handleSearch} className="form">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="输入关键词"
          required
        />
        <button type="submit" disabled={loading}>
          {loading ? "搜索中..." : "搜索"}
        </button>
      </form>
      {error && <p className="error">{error}</p>}
      <ul className="list">
        {results.map((item) => (
          <li
            key={item.id}
            className="list__item list__item--clickable"
            onClick={() => handleArticleClick(item.id)}
          >
            <div className="list__meta">
              <strong>{item.title}</strong>
              <small>{formatDateTime(item.created_at)}</small>
            </div>
            <p>{item.content}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default SearchPage;
