/**
 * 创建文章页面组件
 * 提供表单用于创建新文章
 */
import { useState } from "react";
import { createArticle } from "../api";

function CreatePage({ onCreated }) {
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  /**
   * 处理表单提交
   * 调用后端创建接口，创建新文章
   * 
   * @param {Event} event - 表单提交事件
   */
  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoading(true);
    setMessage("");
    setError("");
    try {
      // 发送数据到后端；后端返回创建的文章（包含 id）
      const article = await createArticle({ title, content });
      setMessage(`文章 #${article.id} 创建成功`);
      setTitle("");
      setContent("");
      if (onCreated) onCreated(article);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="card">
      <h2>创建文章</h2>
      <form onSubmit={handleSubmit} className="form">
        <label>
          标题
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
          />
        </label>
        <label>
          内容
          <textarea
            rows="6"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
          />
        </label>
        <button type="submit" disabled={loading}>
          {loading ? "保存中..." : "保存"}
        </button>
      </form>
      {message && <p className="success">{message}</p>}
      {error && <p className="error">{error}</p>}
    </section>
  );
}

export default CreatePage;
