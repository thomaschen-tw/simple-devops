/**
 * 主应用组件
 * 管理页面导航：主页 -> 搜索页 / 创建页
 */
import { useState } from "react";
import CreatePage from "./pages/CreatePage";
import SearchPage from "./pages/SearchPage";
import HomePage from "./pages/HomePage";

function App() {
  // 当前页面：'home' | 'search' | 'create'
  const [currentPage, setCurrentPage] = useState("home");

  return (
    <div className="app">
      <header className="app__header">
        <h1>My Blog</h1>
        {/* 导航按钮：始终显示，方便快速切换 */}
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
      </header>

      <main className="app__content">
        {/* 根据当前页面渲染对应组件 */}
        {currentPage === "home" && <HomePage onNavigate={setCurrentPage} />}
        {currentPage === "search" && <SearchPage />}
        {currentPage === "create" && (
          <CreatePage onCreated={() => setCurrentPage("search")} />
        )}
      </main>
    </div>
  );
}

export default App;

