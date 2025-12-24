/**
 * 主应用组件
 * 管理页面导航和状态，协调各个页面组件
 */
import { useState } from "react";
import CreatePage from "./pages/CreatePage";
import SearchPage from "./pages/SearchPage";
import HomePage from "./pages/HomePage";
import ArticleDetailPage from "./pages/ArticleDetailPage";

/**
 * App 组件
 * 管理应用的整体布局和页面切换
 * 
 * @returns {JSX.Element} 应用根组件
 */
function App() {
  // 当前页面状态：'home' | 'search' | 'create' | 'detail'
  const [currentPage, setCurrentPage] = useState("home");
  // 当前查看的文章 ID（用于详情页）
  const [currentArticleId, setCurrentArticleId] = useState(null);

  /**
   * 处理文章点击事件
   * 切换到详情页并设置文章 ID
   * 
   * @param {number} articleId - 文章 ID
   */
  const handleArticleClick = (articleId) => {
    setCurrentArticleId(articleId);
    setCurrentPage("detail");
  };

  /**
   * 返回搜索页
   */
  const handleBackToSearch = () => {
    setCurrentArticleId(null);
    setCurrentPage("search");
  };

  return (
    <div className="app">
      <header className="app__header">
        <h1>我的博客</h1>
        {/* 导航按钮：始终显示，方便快速切换页面（详情页时隐藏） */}
        {currentPage !== "detail" && (
          <nav className="nav">
            <button
              className={`nav__btn ${currentPage === "home" ? "nav__btn--active" : ""}`}
              onClick={() => setCurrentPage("home")}
            >
              主页
            </button>
            <button
              className={`nav__btn ${currentPage === "search" ? "nav__btn--active" : ""}`}
              onClick={() => setCurrentPage("search")}
            >
              搜索
            </button>
            <button
              className={`nav__btn ${currentPage === "create" ? "nav__btn--active" : ""}`}
              onClick={() => setCurrentPage("create")}
            >
              创建
            </button>
          </nav>
        )}
      </header>

      <main className="app__content">
        {/* 根据当前页面状态渲染对应组件 */}
        {currentPage === "home" && <HomePage onNavigate={setCurrentPage} />}
        {currentPage === "search" && (
          <SearchPage onArticleClick={handleArticleClick} />
        )}
        {currentPage === "create" && (
          <CreatePage onCreated={() => setCurrentPage("search")} />
        )}
        {currentPage === "detail" && currentArticleId && (
          <ArticleDetailPage
            articleId={currentArticleId}
            onBack={handleBackToSearch}
          />
        )}
      </main>
    </div>
  );
}

export default App;
