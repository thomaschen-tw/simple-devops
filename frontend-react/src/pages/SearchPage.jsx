/**
 * 搜索页面组件
 * 提供文章搜索功能，显示搜索结果列表
 */
import { useState } from "react";
import { searchArticles } from "../api";

function SearchPage() {
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
          <li key={item.id} className="list__item">
            <div className="list__meta">
              <strong>{item.title}</strong>
              <small>{new Date(item.created_at).toLocaleString()}</small>
            </div>
            <p>{item.content}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default SearchPage;
