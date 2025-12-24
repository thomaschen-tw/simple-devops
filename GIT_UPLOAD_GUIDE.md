# 📤 代码上传到 GitHub 指南

## 快速上传步骤

### 1. 添加远程仓库

```bash
cd /Users/xiaotongchen/aiTools/simple-devops

# 替换 YOUR_USERNAME 为你的 GitHub 用户名
git remote add origin https://github.com/YOUR_USERNAME/simple-devops.git

# 或者使用 SSH（如果你配置了 SSH key）
# git remote add origin git@github.com:YOUR_USERNAME/simple-devops.git
```

### 2. 推送到 GitHub

```bash
# 首次推送
git push -u origin main
```

## 完整命令示例

假设你的 GitHub 用户名是 `xiaotongchen`：

```bash
cd /Users/xiaotongchen/aiTools/simple-devops

# 1. 添加远程仓库
git remote add origin https://github.com/xiaotongchen/simple-devops.git

# 2. 推送到 GitHub
git push -u origin main
```

## 如果遇到问题

### 问题 1: 远程仓库已存在

如果提示 `remote origin already exists`，先删除再添加：

```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/simple-devops.git
```

### 问题 2: 需要身份验证

GitHub 现在要求使用 Personal Access Token (PAT) 而不是密码：

1. 生成 Token：
   - 访问：https://github.com/settings/tokens
   - 点击 "Generate new token (classic)"
   - 选择权限：`repo`（全部权限）
   - 复制生成的 token

2. 使用 Token：
   ```bash
   # 推送时会提示输入用户名和密码
   # 用户名：你的 GitHub 用户名
   # 密码：粘贴刚才生成的 token
   git push -u origin main
   ```

### 问题 3: 使用 SSH（推荐，免密码）

1. 检查是否已有 SSH key：
   ```bash
   ls -al ~/.ssh
   ```

2. 如果没有，生成新的 SSH key：
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

3. 添加 SSH key 到 GitHub：
   ```bash
   cat ~/.ssh/id_ed25519.pub
   # 复制输出内容，添加到 GitHub: Settings -> SSH and GPG keys -> New SSH key
   ```

4. 使用 SSH URL：
   ```bash
   git remote set-url origin git@github.com:YOUR_USERNAME/simple-devops.git
   git push -u origin main
   ```

## 后续更新代码

```bash
# 1. 查看修改的文件
git status

# 2. 添加修改的文件
git add .

# 3. 提交更改
git commit -m "描述你的更改"

# 4. 推送到 GitHub
git push
```

## 验证上传成功

1. 访问你的 GitHub 仓库：`https://github.com/YOUR_USERNAME/simple-devops`
2. 应该能看到所有文件
3. GitHub Actions 会自动触发构建（如果已配置）

## 注意事项

- ✅ `.gitignore` 已配置，不会上传敏感文件（如 `.env`、`node_modules` 等）
- ✅ 所有代码文件都已包含
- ✅ GitHub Actions workflows 已配置，推送后会自动构建镜像

