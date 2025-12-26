# Python 版本说明

## 🐍 项目使用的 Python 版本

**本项目明确要求使用 Python 3.13**

### 配置位置

1. **pyproject.toml**
   ```toml
   requires-python = ">=3.13"
   ```

2. **Dockerfile**
   ```dockerfile
   FROM python:3.13-slim AS runtime
   ```

3. **CI/CD (.github/workflows/backend.yml)**
   ```yaml
   - name: Set up Python 3.13
     run: uv python install 3.13
   ```

4. **uv.lock**
   ```toml
   requires-python = ">=3.13"
   ```

## ⚠️ 关于 Python 3.12.9 的说明

### 为什么某些工具推荐 3.12.9？

某些 IDE（如 VS Code、PyCharm）或工具可能会推荐 Python 3.12.9，这是因为：

1. **工具的默认推荐**：工具可能基于"稳定版本"推荐 3.12.9
2. **兼容性考虑**：3.12 是更早发布的版本，工具可能认为更稳定
3. **自动检测**：工具可能检测到系统已安装的 Python 版本

### ✅ 但本项目使用 Python 3.13

**原因**：
- ✅ Python 3.13 是最新的稳定版本
- ✅ 性能更好，类型提示支持更完善
- ✅ 所有依赖包都兼容 Python 3.13
- ✅ uv 完全支持 Python 3.13

**如何确保使用正确的版本**：

```bash
# 1. 使用 uv 安装 Python 3.13
uv python install 3.13

# 2. 为项目固定版本
uv python pin 3.13

# 3. 验证版本
uv run python --version
# 应该显示：Python 3.13.x
```

## 🔧 IDE 配置

### VS Code

1. 打开命令面板（Cmd+Shift+P / Ctrl+Shift+P）
2. 选择 "Python: Select Interpreter"
3. 选择 `.venv/bin/python`（uv 创建的虚拟环境）
4. 确认版本是 3.13.x

### PyCharm

1. 打开项目设置
2. 选择 Python Interpreter
3. 选择 `.venv/bin/python`
4. 确认版本是 3.13.x

## 📊 版本对比

| 版本 | 状态 | 项目使用 |
|------|------|---------|
| Python 3.12.9 | ⚠️ 工具可能推荐 | ❌ 不使用 |
| Python 3.13.x | ✅ 项目要求 | ✅ **使用** |

## ✅ 总结

- **项目要求**：Python 3.13
- **工具推荐 3.12.9**：可以忽略，使用项目的配置
- **确保正确版本**：使用 `uv python install 3.13` 和 `uv python pin 3.13`
- **验证方法**：`uv run python --version` 应该显示 3.13.x

## 📚 相关文档

- [backend-fastapi/README.md](backend-fastapi/README.md) - 后端项目说明
- [backend-fastapi/QUICKSTART.md](backend-fastapi/QUICKSTART.md) - 快速开始指南
- [backend-fastapi/WHY_VIRTUAL_ENV.md](backend-fastapi/WHY_VIRTUAL_ENV.md) - 虚拟环境说明

