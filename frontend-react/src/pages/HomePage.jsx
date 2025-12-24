/**
 * 主页组件
 * 提供导航按钮，引导用户进入搜索或创建页面
 */

/**
 * HomePage 组件
 * 显示欢迎信息和导航按钮
 * 
 * @param {Object} props - 组件属性
 * @param {Function} props.onNavigate - 页面导航回调函数，接收目标页面名称
 * @returns {JSX.Element} 主页组件
 */
function HomePage({ onNavigate }) {
  return (
    <section className="card home-page">
      <h2>欢迎来到我的博客</h2>
      <p className="home-page__description">
        在这里你可以搜索已有文章，或者创建新的文章内容。
      </p>
      <div className="home-page__actions">
        <button
          className="btn btn--primary btn--large"
          onClick={() => onNavigate("search")}
        >
          🔍 搜索文章
        </button>
        <button
          className="btn btn--secondary btn--large"
          onClick={() => onNavigate("create")}
        >
          ✏️ 创建文章
        </button>
      </div>
    </section>
  );
}

export default HomePage;
