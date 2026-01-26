# N8N 反馈工单功能开发文档

## 日期
2025-12-25

## 功能概述
实现了用户反馈页面和 7x24 小时自动化工单处理系统，通过 n8n 工作流实现自动化处理。

## 修改内容总结

### 1. 后端 API 开发

#### 1.1 数据库模型 (`backend-fastapi/app/models.py`)
- **新增 Ticket 模型**：用于存储用户反馈工单
  - 字段：`id`, `issue_title`, `issue_description`, `customer_name`, `customer_email`, `urgency`, `n8n_sent`, `created_at`
  - `n8n_sent` 字段用于跟踪工单是否成功发送到 n8n（pending/success/failed）
- **新增 UrgencyLevel 枚举**：定义工单紧急程度（critical, high, normal, low）
- **数据库配置更新**：本地开发默认端口改为 5434（映射到容器内部 5432）

#### 1.2 API 路由 (`backend-fastapi/app/routes.py`)
- **新增 `/feedback` POST 接口**：接收用户反馈并处理
  - 先保存到数据库（确保数据不丢失）
  - 然后发送到 n8n webhook 进行自动化处理
  - 即使 n8n 失败，也返回成功（因为数据已保存）
- **数据格式**：与 n8n.json 工作流完全匹配
  - `issue_title`: 问题标题
  - `issue_description`: 问题描述
  - `customer_name`: 客户姓名
  - `customer_email`: 客户邮箱
  - `urgency`: 紧急程度（critical, high, normal, low）
- **错误处理**：完善的错误处理和日志记录

#### 1.3 依赖更新 (`backend-fastapi/requirements.txt`)
- 新增 `requests==2.31.0`：用于调用 n8n webhook
- 新增 `email-validator>=2.0.0`：用于邮箱格式验证

#### 1.4 Dockerfile (`backend-fastapi/Dockerfile`)
- 添加了数据库端口配置说明注释

#### 1.5 测试工具 (`backend-fastapi/app/n8ntest.py`)
- **新增测试脚本**：用于测试 n8n webhook 连接
- 支持三种模式：
  - 批量模式：依次发送四种工单模板
  - 单次模式：循环发送工单
  - 测试单个工单
- 包含详细的错误处理和调试信息

#### 1.6 N8N 工作流配置 (`backend-fastapi/app/n8n.json`)
- **新增 n8n 工作流配置文件**：定义了完整的工单处理流程
- 工作流节点：
  1. 接收工单（Webhook）
  2. AI 工单分析
  3. 工单分支（根据紧急程度）
  4. 不同紧急程度的处理：
     - critical: 发送紧急邮件 + Slack 通知
     - high: 发送 Slack 通知
     - normal: 延迟处理
     - low: 自动回复客户邮件

### 2. 前端开发

#### 2.1 反馈页面 (`frontend-react/src/pages/FeedbackPage.jsx`)
- **新增反馈页面组件**：提供用户反馈表单
- 表单字段：
  - 问题标题（必填）
  - 问题描述（必填，多行文本）
  - 客户姓名（必填）
  - 客户邮箱（必填，邮箱验证）
  - 紧急程度（下拉选择：低/普通/高/紧急）
- **动态提示**：根据选择的紧急程度显示相应的处理提示
- **用户体验优化**：提交后显示成功/错误消息，自动清空表单

#### 2.2 API 集成 (`frontend-react/src/api.js`)
- **新增 `submitFeedback` 函数**：调用后端反馈接口
- 完善的错误处理

#### 2.3 应用路由 (`frontend-react/src/App.jsx`)
- **新增反馈页面路由**：添加"反馈"导航按钮
- 集成到主应用导航系统

## 技术架构

### 数据流程
1. 用户在前端填写反馈表单
2. 前端调用 `/feedback` API
3. 后端先保存到数据库（tickets 表）
4. 后端发送到 n8n webhook (`http://localhost:5678/webhook-test/new-ticket`)
5. n8n 工作流根据紧急程度进行自动化处理

### 数据库设计
- **tickets 表**：
  - `id`: 主键
  - `issue_title`: 问题标题（索引）
  - `issue_description`: 问题描述
  - `customer_name`: 客户姓名
  - `customer_email`: 客户邮箱（索引）
  - `urgency`: 紧急程度（索引）
  - `n8n_sent`: n8n 发送状态（pending/success/failed）
  - `created_at`: 创建时间

### N8N 工作流
- Webhook 路径：`/webhook-test/new-ticket`（测试模式）
- 工作流会根据 `urgency` 字段进行分支处理
- 支持 AI 分析、邮件通知、Slack 通知等功能

## 配置说明

### 环境变量
- `N8N_WEBHOOK_URL`: n8n webhook 地址（默认：`http://localhost:5678/webhook-test/new-ticket`）
- `DATABASE_URL`: 数据库连接字符串（默认：`postgresql+psycopg://postgres:postgres@localhost:5434/blog`）

### 数据库配置
- 本地开发：PostgreSQL 容器端口映射 `5434:5432`
- 数据库名：`blog`
- 用户名/密码：`postgres/postgres`

## 使用说明

### 1. 启动服务
```bash
# 启动 PostgreSQL 数据库
docker start base-postgres

# 启动后端服务
cd backend-fastapi
python3 -m uvicorn app.main:app --reload --port 8000

# 启动前端服务
cd frontend-react
npm run dev
```

### 2. 配置 N8N
1. 访问 `http://localhost:5678`
2. 导入 `backend-fastapi/app/n8n.json` 工作流
3. 在画布上点击 "Execute workflow" 按钮（测试模式）
4. 配置 Gmail 和 Slack 凭证（如需要）

### 3. 测试工单提交
```bash
# 使用测试脚本
cd backend-fastapi
python3 app/n8ntest.py

# 或通过前端页面
访问 http://localhost:5173，点击"反馈"按钮
```

## 注意事项

### 重要信息（不上传）
- 数据库密码和连接信息应通过环境变量配置
- n8n 的 Gmail 和 Slack 凭证需要在 n8n 界面中配置，不存储在代码中
- 生产环境应使用生产模式 webhook (`/webhook/new-ticket`)，需要激活工作流

### 安全建议
- 生产环境应使用环境变量配置敏感信息
- 建议添加 API 限流和验证码机制
- 邮箱验证使用 `email-validator` 库确保格式正确

## 文件清单

### 新增文件
- `backend-fastapi/app/n8ntest.py` - n8n webhook 测试工具
- `backend-fastapi/app/n8n.json` - n8n 工作流配置
- `frontend-react/src/pages/FeedbackPage.jsx` - 反馈页面组件
- `N8N_FEEDBACK_FEATURE.md` - 本文档

### 修改文件
- `backend-fastapi/app/models.py` - 新增 Ticket 模型
- `backend-fastapi/app/routes.py` - 新增反馈 API 接口
- `backend-fastapi/requirements.txt` - 新增依赖
- `backend-fastapi/Dockerfile` - 添加注释说明
- `frontend-react/src/api.js` - 新增反馈 API 函数
- `frontend-react/src/App.jsx` - 新增反馈页面路由

## 后续优化建议

1. **工作流激活**：生产环境应使用生产模式 webhook 并激活工作流
2. **数据统计**：添加工单统计和查询接口
3. **邮件模板**：优化自动回复邮件模板
4. **监控告警**：添加 n8n 工作流执行监控
5. **用户界面**：添加工单列表和管理页面

