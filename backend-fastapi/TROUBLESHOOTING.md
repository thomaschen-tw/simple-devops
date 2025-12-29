# 故障排查指南

## ❌ 问题：`zsh: command not found: uv`

### 问题描述

执行 `uv run uvicorn app.main:app --reload` 时出现：
```
zsh: command not found: uv
```

### 原因分析

**uv 未安装或未添加到 PATH**

可能的原因：
1. uv 未安装
2. uv 已安装但未添加到 PATH 环境变量
3. 当前 shell 会话未加载 PATH 更新

### 解决方案

#### 方案一：安装 uv（如果未安装）

```bash
# 安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 验证安装
ls -la ~/.local/bin/uv
```

#### 方案二：添加到 PATH（如果已安装但找不到）

**临时添加（当前终端会话）**：
```bash
export PATH="$HOME/.local/bin:$PATH"

# 验证
which uv
uv --version
```

**永久添加（推荐）**：

对于 zsh（macOS 默认）：
```bash
# 添加到 ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc

# 重新加载配置
source ~/.zshrc

# 验证
which uv
uv --version
```

对于 bash：
```bash
# 添加到 ~/.bashrc 或 ~/.bash_profile
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### 方案三：使用完整路径（临时方案）

```bash
# 直接使用完整路径
~/.local/bin/uv run uvicorn app.main:app --reload
```

### 验证安装

安装和配置完成后，验证：

```bash
# 1. 检查 uv 是否在 PATH 中
which uv
# 应该显示：/Users/你的用户名/.local/bin/uv

# 2. 检查 uv 版本
uv --version
# 应该显示：uv 0.x.x

# 3. 检查 Python 版本
uv python list
# 应该显示已安装的 Python 版本
```

### 完整设置流程

```bash
# 1. 安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. 添加到 PATH（永久）
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 3. 验证安装
uv --version

# 4. 安装 Python 3.13
uv python install 3.13

# 5. 进入项目目录
cd backend-fastapi

# 6. 安装依赖
uv sync

# 7. 运行项目
export DATABASE_URL="postgresql+psycopg://demo:demo@localhost:5433/demo"
uv run uvicorn app.main:app --reload
```

## ❌ 问题：Python 版本不对

### 问题描述

虽然系统有 Python 3.13，但项目可能使用了错误的版本。

### 解决方案

```bash
# 1. 使用 uv 安装 Python 3.13
uv python install 3.13

# 2. 为项目固定版本
cd backend-fastapi
uv python pin 3.13

# 3. 验证版本
uv run python --version
# 应该显示：Python 3.13.x
```

## ❌ 问题：虚拟环境未创建

### 问题描述

执行 `uv run` 时提示找不到虚拟环境。

### 解决方案

```bash
# 确保在项目目录
cd backend-fastapi

# 同步依赖（会自动创建虚拟环境）
uv sync

# 验证虚拟环境
ls -la .venv/
```

## ❌ 问题：依赖安装失败

### 问题描述

执行 `uv sync` 时出现错误。

### 解决方案

```bash
# 1. 清理缓存
uv cache clean

# 2. 重新同步
uv sync

# 3. 如果还是失败，检查网络连接
ping pypi.org
```

## ❌ 问题：IDE 找不到包

### 问题描述

IDE（VS Code、PyCharm）提示找不到已安装的包。

### 解决方案

**VS Code**：
1. 打开命令面板（Cmd+Shift+P）
2. 选择 "Python: Select Interpreter"
3. 选择 `.venv/bin/python`（项目虚拟环境）

**PyCharm**：
1. 打开项目设置
2. 选择 Python Interpreter
3. 选择 `.venv/bin/python`

**验证**：
```bash
# 在终端中验证包是否安装
uv run python -c "import fastapi; print(fastapi.__version__)"
```

## 📚 相关文档

- [快速开始指南](QUICKSTART.md)
- [uv 迁移指南](UV_MIGRATION_GUIDE.md)
- [Python 版本说明](../PYTHON_VERSION_CLARIFICATION.md)

## 💡 常见错误总结

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `command not found: uv` | uv 未安装或未在 PATH | 安装 uv 并添加到 PATH |
| `Python version not found` | Python 3.13 未安装 | `uv python install 3.13` |
| `ModuleNotFoundError` | 虚拟环境未创建 | `uv sync` |
| IDE 找不到包 | IDE 未选择正确的解释器 | 选择 `.venv/bin/python` |

