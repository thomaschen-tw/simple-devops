# 快速开始指南 - uv + Python 3.13

## 🚀 快速开始

### 1. 安装 uv（如果还没有）

```bash
# macOS/Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# 添加到 PATH（如果还没有）
export PATH="$HOME/.local/bin:$PATH"
```

### 2. 安装 Python 3.13

```bash
uv python install 3.13
```

### 3. 安装项目依赖

```bash
cd backend-fastapi
uv sync
```

这会自动：
- 创建虚拟环境（`.venv/`）
- 安装所有依赖
- 生成 `uv.lock` 文件

### 4. 运行项目

```bash
# 方法一：使用 uv run（推荐）
uv run uvicorn app.main:app --reload

# 方法二：激活虚拟环境后运行
source .venv/bin/activate
uvicorn app.main:app --reload
```

### 5. 运行测试

```bash
uv run pytest -v
```

## 📝 常用命令

### 依赖管理

```bash
# 添加依赖
uv add package-name

# 添加开发依赖
uv add --dev package-name

# 移除依赖
uv remove package-name

# 更新依赖
uv sync --upgrade

# 查看依赖
uv tree
```

### Python 版本管理

```bash
# 安装 Python 版本
uv python install 3.13

# 为项目固定 Python 版本
uv python pin 3.13

# 列出已安装的 Python 版本
uv python list
```

### 运行命令

```bash
# 运行 Python 脚本
uv run python script.py

# 运行应用
uv run uvicorn app.main:app

# 运行测试
uv run pytest

# 运行任何命令（自动使用虚拟环境）
uv run <command>
```

## 🐳 Docker 使用

### 构建镜像

```bash
docker build -t backend-fastapi:latest ./backend-fastapi
```

### 使用 docker-compose

```bash
# 从项目根目录
docker compose up --build
```

## 🔧 IDE 配置

### VS Code

1. 打开项目
2. 选择 Python 解释器：`.venv/bin/python`
3. 如果 IDE 提示找不到包，重启 IDE 或重新加载窗口

### PyCharm

1. 打开项目设置
2. 选择 Python 解释器：`.venv/bin/python`
3. 应用更改

## ⚠️ 常见问题

### 1. IDE 提示找不到包

**原因**：IDE 没有识别到 uv 创建的虚拟环境

**解决**：
- 手动选择解释器：`.venv/bin/python`
- 重启 IDE
- 或者使用 `uv run` 运行命令

### 2. 命令找不到：uv

**原因**：uv 没有添加到 PATH

**解决**：
```bash
export PATH="$HOME/.local/bin:$PATH"
# 或者添加到 ~/.zshrc 或 ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### 3. Python 版本不对

**解决**：
```bash
uv python install 3.13
uv python pin 3.13
uv sync
```

## 📚 更多信息

- [uv 迁移指南](./UV_MIGRATION_GUIDE.md)
- [uv 迁移总结](./UV_MIGRATION_SUMMARY.md)
- [代码审核报告](./CODE_REVIEW.md)
- [uv 官方文档](https://docs.astral.sh/uv/)

