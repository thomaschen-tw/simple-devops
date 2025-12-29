# Git 分支操作学习指南

本文档基于实际项目操作，详细说明如何将最新内容覆盖到指定分支。

## 📋 场景说明

**目标**：将 main 分支的最新更改（包括新创建的 Terraform 配置）覆盖到 `tf` 分支。

**操作流程**：
1. 在 main 分支提交更改
2. 切换到 tf 分支
3. 合并 main 分支到 tf 分支
4. 解决冲突（如果有）
5. 推送到远程仓库

## 🔍 第一步：检查当前状态

在开始操作前，先了解当前的 Git 状态。

### 1.1 查看工作区状态

```bash
git status
```

**输出示例**：
```
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  modified:   backend-fastapi/DOCS_INDEX.md
  modified:   backend-fastapi/QUICKSTART.md
  modified:   backend-fastapi/README.md

Untracked files:
  backend-fastapi/TROUBLESHOOTING.md
  terraform/
```

**说明**：
- `Changes not staged for commit`：已修改但未暂存的文件
- `Untracked files`：新文件，Git 尚未跟踪

### 1.2 查看所有分支

```bash
git branch -a
```

**输出示例**：
```
* main              # * 表示当前所在分支
  n8n_monitor
  tf
  remotes/origin/main
  remotes/origin/tf
```

**说明**：
- 本地分支：`main`, `n8n_monitor`, `tf`
- 远程分支：`remotes/origin/main`, `remotes/origin/tf`
- `*` 标记当前分支

### 1.3 查看提交历史

```bash
git log --oneline -5
```

**输出示例**：
```
1d11271 simple docs change
0aa074c Merge pull request #1
34ab35f docs summary
54d7b20 feat: 添加 N8N 反馈工单功能
bec84ae dockerfile optimization
```

**说明**：
- `--oneline`：单行显示，简洁格式
- `-5`：只显示最近 5 条提交

## 📦 第二步：提交更改到 main 分支

### 2.1 添加所有文件到暂存区

```bash
git add -A
```

**命令说明**：
- `git add -A`：添加所有更改（包括修改、新增、删除）
- 等价于 `git add .`（但 `-A` 更明确）

**其他常用选项**：
- `git add .`：添加当前目录及子目录的更改
- `git add <file>`：添加特定文件
- `git add -u`：只添加已跟踪文件的修改（不包括新文件）

### 2.2 查看暂存区状态

```bash
git status --short
```

**输出示例**：
```
M  backend-fastapi/DOCS_INDEX.md      # M = Modified（修改）
A  terraform/README.md                  # A = Added（新增）
D  old-file.md                          # D = Deleted（删除）
```

**状态标记说明**：
- `M`：已修改
- `A`：已添加（新文件）
- `D`：已删除
- `??`：未跟踪的文件

### 2.3 提交更改

```bash
git commit -m "feat: 添加 Terraform AWS 部署配置

- 添加完整的 Terraform 配置用于 AWS 部署
- 包含 VPC、RDS、ECS、ALB 等模块
- 添加详细的部署文档和指南
- 更新后端文档索引"
```

**命令说明**：
- `-m`：指定提交信息
- 多行提交信息：第一行是简短描述，空行后是详细说明

**提交信息规范**（Conventional Commits）：
- `feat:`：新功能
- `fix:`：修复 bug
- `docs:`：文档更新
- `style:`：代码格式（不影响功能）
- `refactor:`：重构
- `test:`：测试相关
- `chore:`：构建/工具相关

**提交结果**：
```
[main 25f44a1] feat: 添加 Terraform AWS 部署配置
 32 files changed, 3270 insertions(+), 3 deletions(-)
```

**说明**：
- `25f44a1`：提交的哈希值（前 7 位）
- `32 files changed`：32 个文件被修改
- `3270 insertions`：新增 3270 行
- `3 deletions`：删除 3 行

## 🔀 第三步：切换到 tf 分支并合并

### 3.1 切换到 tf 分支

```bash
git checkout tf
```

**命令说明**：
- `git checkout <branch>`：切换到指定分支
- 切换前确保当前分支的更改已提交

**输出示例**：
```
Switched to branch 'tf'
Your branch is up to date with 'origin/tf'.
```

**现代 Git 命令**（Git 2.23+）：
```bash
git switch tf  # 更直观的切换分支命令
```

### 3.2 合并 main 分支到当前分支（tf）

```bash
git merge main --no-edit
```

**命令说明**：
- `git merge <branch>`：将指定分支合并到当前分支
- `--no-edit`：使用自动生成的合并提交信息，不打开编辑器

**合并结果（有冲突）**：
```
Auto-merging frontend-react/src/api.js
Auto-merging terraform/.gitignore
CONFLICT (add/add): Merge conflict in terraform/.gitignore
Auto-merging terraform/README.md
CONFLICT (add/add): Merge conflict in terraform/README.md
...
Automatic merge failed; fix conflicts and then commit the result.
```

**说明**：
- `Auto-merging`：自动合并成功的文件
- `CONFLICT`：冲突文件，需要手动解决
- `add/add`：两个分支都添加了同名文件，内容不同

## ⚠️ 第四步：解决合并冲突

### 4.1 查看冲突状态

```bash
git status
```

**输出示例**：
```
On branch tf
Your branch is up to date with 'origin/tf'.

You have unmerged paths.
  (fix conflicts and run "git commit")
  (use "git merge --abort" to abort the merge)

Unmerged paths:
  (use "git add <file>..." to mark resolution)
	both added:      terraform/.gitignore
	both added:      terraform/README.md
	both added:      terraform/main.tf
	...
```

**说明**：
- `Unmerged paths`：未解决的冲突文件
- `both added`：两个分支都添加了该文件

### 4.2 解决冲突的策略

#### 策略 1：使用当前分支（tf）的版本

```bash
git checkout --ours terraform/README.md
git add terraform/README.md
```

#### 策略 2：使用合并分支（main）的版本（我们使用的）

```bash
git checkout --theirs terraform/
git add terraform/
```

**命令说明**：
- `--ours`：使用当前分支（tf）的版本
- `--theirs`：使用合并分支（main）的版本
- 可以指定文件或目录

**为什么使用 `--theirs`？**
- 我们的目标是**覆盖** tf 分支
- main 分支包含最新的、完整的配置
- 所以使用 main 分支的版本

### 4.3 手动解决冲突（如果需要）

如果自动解决不够，可以手动编辑冲突文件：

**冲突标记**：
```markdown
<<<<<<< HEAD
这是 tf 分支的内容
=======
这是 main 分支的内容
>>>>>>> main
```

**解决步骤**：
1. 打开冲突文件
2. 找到冲突标记
3. 选择要保留的内容（或合并两者）
4. 删除冲突标记
5. 保存文件
6. `git add <file>` 标记为已解决

### 4.4 完成合并

```bash
git commit -m "feat: 更新 Terraform AWS 部署配置

- 使用最新的 Terraform 配置覆盖 tf 分支
- 包含完整的模块化架构
- 添加详细的部署文档"
```

**说明**：
- 冲突解决后必须提交才能完成合并
- 这是合并提交（merge commit）

## 🚀 第五步：推送到远程仓库

### 5.1 推送到远程 tf 分支

```bash
git push origin tf
```

**命令说明**：
- `git push <remote> <branch>`：推送到远程仓库
- `origin`：默认远程仓库名称
- `tf`：要推送的分支名

**输出示例**：
```
To github.com:thomaschen-tw/simple-devops.git
   6b015de..eab0e4c  tf -> tf
```

**说明**：
- `6b015de..eab0e4c`：推送的提交范围
- `tf -> tf`：本地 tf 分支推送到远程 tf 分支

### 5.2 切换回 main 分支

```bash
git checkout main
```

**或者**：
```bash
git switch main  # Git 2.23+
```

## 📊 操作总结

### 完整命令序列

```bash
# 1. 检查状态
git status
git branch -a

# 2. 提交到 main 分支
git add -A
git commit -m "feat: 添加 Terraform AWS 部署配置"

# 3. 切换到 tf 分支
git checkout tf

# 4. 合并 main 分支
git merge main --no-edit

# 5. 解决冲突（使用 main 分支的版本）
git checkout --theirs terraform/
git add terraform/
git commit -m "feat: 更新 Terraform AWS 部署配置"

# 6. 推送到远程
git push origin tf

# 7. 切换回 main 分支
git checkout main
```

## 🎓 Git 概念详解

### 1. 分支（Branch）

**什么是分支？**
- 分支是提交的指针
- 可以独立开发，不影响其他分支
- 默认分支通常是 `main` 或 `master`

**创建分支**：
```bash
git branch <branch-name>        # 创建分支
git checkout <branch-name>      # 切换到分支
git checkout -b <branch-name>   # 创建并切换
```

**查看分支**：
```bash
git branch           # 本地分支
git branch -a        # 所有分支（包括远程）
git branch -r        # 远程分支
```

### 2. 合并（Merge）

**合并类型**：

1. **Fast-forward 合并**：
   - 当前分支没有新提交
   - 直接移动指针
   - 不会创建合并提交

2. **三方合并**：
   - 两个分支都有新提交
   - 创建合并提交
   - 可能需要解决冲突

**合并命令**：
```bash
git merge <branch>              # 合并分支
git merge --no-ff <branch>       # 强制创建合并提交
git merge --no-edit <branch>    # 使用自动提交信息
```

### 3. 冲突（Conflict）

**冲突原因**：
- 两个分支修改了同一文件的同一部分
- Git 无法自动决定保留哪个版本

**冲突解决**：
1. 查看冲突：`git status`
2. 打开冲突文件
3. 手动编辑或使用策略命令
4. 标记为已解决：`git add`
5. 完成合并：`git commit`

### 4. 远程仓库（Remote）

**查看远程**：
```bash
git remote -v                    # 查看远程仓库
git remote show origin           # 查看远程详情
```

**推送和拉取**：
```bash
git push origin <branch>         # 推送到远程
git pull origin <branch>         # 从远程拉取并合并
git fetch origin                 # 只获取，不合并
```

## 💡 最佳实践

### 1. 提交前检查

```bash
git status                        # 检查工作区状态
git diff                         # 查看具体更改
git diff --staged                # 查看暂存区更改
```

### 2. 提交信息规范

- 使用清晰、描述性的提交信息
- 遵循 Conventional Commits 规范
- 第一行简短（50 字符内），详细说明放在空行后

### 3. 分支管理

- 主分支（main/master）保持稳定
- 功能分支从主分支创建
- 合并前先拉取最新代码：`git pull origin main`
- 合并后及时删除已合并的分支

### 4. 冲突处理

- 合并前先更新本地分支
- 小冲突及时解决，避免积累
- 大冲突可以寻求团队帮助
- 使用工具（如 VS Code）可视化解决冲突

## 🔧 常用命令速查

### 分支操作

```bash
git branch                        # 列出本地分支
git branch -a                    # 列出所有分支
git branch <name>                # 创建分支
git checkout <branch>             # 切换分支
git checkout -b <branch>          # 创建并切换
git switch <branch>               # 切换分支（Git 2.23+）
git branch -d <branch>           # 删除分支
git branch -D <branch>           # 强制删除分支
```

### 合并操作

```bash
git merge <branch>                # 合并分支
git merge --no-ff <branch>        # 强制创建合并提交
git merge --abort                 # 取消合并
git merge --continue              # 解决冲突后继续
```

### 冲突解决

```bash
git status                        # 查看冲突
git checkout --ours <file>        # 使用当前分支版本
git checkout --theirs <file>     # 使用合并分支版本
git add <file>                    # 标记为已解决
```

### 远程操作

```bash
git push origin <branch>          # 推送到远程
git pull origin <branch>          # 拉取并合并
git fetch origin                  # 获取远程更新
git push -u origin <branch>      # 推送并设置上游
```

## 📚 延伸学习

### 1. Rebase vs Merge

**Merge（合并）**：
- 保留分支历史
- 创建合并提交
- 历史图更复杂

**Rebase（变基）**：
- 线性历史
- 不创建合并提交
- 历史更清晰

```bash
git rebase <branch>               # 变基到指定分支
git rebase -i <commit>            # 交互式变基
```

### 2. Cherry-pick

**选择性地应用提交**：
```bash
git cherry-pick <commit-hash>     # 应用特定提交
git cherry-pick <hash1> <hash2>    # 应用多个提交
```

### 3. Stash（暂存）

**临时保存更改**：
```bash
git stash                         # 暂存当前更改
git stash list                    # 查看暂存列表
git stash pop                     # 恢复并删除暂存
git stash apply                   # 恢复但不删除
```

## ⚠️ 注意事项

1. **合并前备份**：重要更改合并前先备份
2. **不要强制推送主分支**：`git push --force` 会覆盖历史
3. **及时解决冲突**：避免冲突积累
4. **提交前测试**：确保代码可以正常运行
5. **使用分支保护**：保护重要分支（如 main）

## 🎯 总结

本次操作的核心步骤：

1. ✅ **提交更改**：`git add` + `git commit`
2. ✅ **切换分支**：`git checkout tf`
3. ✅ **合并分支**：`git merge main`
4. ✅ **解决冲突**：`git checkout --theirs`
5. ✅ **推送远程**：`git push origin tf`

通过这些操作，我们成功将 main 分支的最新内容覆盖到了 tf 分支。

---

**参考资源**：
- [Git 官方文档](https://git-scm.com/doc)
- [Pro Git 电子书](https://git-scm.com/book)
- [GitHub Guides](https://guides.github.com/)

