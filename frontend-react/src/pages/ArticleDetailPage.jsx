/**
 * 文章详情页面组件
 * 显示单篇文章的完整内容
 */
import { useState, useEffect } from "react";
import { getArticle } from "../api";

/**
 * ArticleDetailPage 组件
 * 根据文章 ID 获取并显示文章详情
 * 
 * @param {Object} props - 组件属性
 * @param {number} props.articleId - 文章 ID
 * @param {Function} props.onBack - 返回回调函数
 * @returns {JSX.Element} 文章详情页组件
 */
function ArticleDetailPage({ articleId, onBack }) {
  const [article, setArticle] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    /**
     * 加载文章详情
     */
    async function loadArticle() {
      setLoading(true);
      setError("");
      try {
        const data = await getArticle(articleId);
        setArticle(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    }

    if (articleId) {
      loadArticle();
    }
  }, [articleId]);

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

  if (loading) {
    return (
      <section className="card">
        <p>加载中...</p>
      </section>
    );
  }

  if (error) {
    return (
      <section className="card">
        <p className="error">{error}</p>
        <button onClick={onBack} className="btn btn--primary">
          返回
        </button>
      </section>
    );
  }

  if (!article) {
    return (
      <section className="card">
        <p>文章不存在</p>
        <button onClick={onBack} className="btn btn--primary">
          返回
        </button>
      </section>
    );
  }

  return (
    <section className="card article-detail">
      <div className="article-detail__header">
        <button onClick={onBack} className="btn btn--secondary">
          ← 返回
        </button>
        <h2 className="article-detail__title">{article.title}</h2>
        <p className="article-detail__meta">
          创建时间：{formatDateTime(article.created_at)}
        </p>
      </div>
      <div className="article-detail__content">
        <p>{article.content}</p>
      </div>
    </section>
  );
}

export default ArticleDetailPage;

