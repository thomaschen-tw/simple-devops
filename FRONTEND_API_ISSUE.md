# 前端 API 调用失败问题分析

## 问题现象

前端页面显示 "failed to fetch"，搜索和创建功能都无法使用。

## 根本原因

### 1. API 地址配置错误

**之前的配置**（错误）:
```javascript
// frontend-react/Dockerfile
ARG VITE_API_BASE_URL=http://backend:8000
```

**问题分析**:
- `http://backend:8000` 是 Docker 容器内的服务名
- 浏览器运行在用户的电脑上（宿主机），不在 Docker 容器内
- 浏览器无法解析 `backend` 这个服务名，因为它不是 DNS 记录
- 浏览器只能访问 `localhost` 或 `127.0.0.1`

**正确的配置**:
```javascript
// frontend-react/Dockerfile
ARG VITE_API_BASE_URL=http://localhost:8000
```

### 2. 网络架构理解

```
用户浏览器 (宿主机)
    ↓ HTTP 请求
localhost:5173 (前端容器端口映射)
    ↓ 前端代码执行
fetch("http://backend:8000/search")  ❌ 浏览器无法解析 "backend"
    ↓ 应该使用
fetch("http://localhost:8000/search") ✅ 浏览器可以访问
    ↓ HTTP 请求
localhost:8000 (后端容器端口映射)
    ↓
后端容器 (backend)
```

### 3. 为什么容器内可以使用服务名？

在 Docker Compose 中：
- 容器之间可以通过服务名通信（`backend`、`postgres`）
- 这是因为 Docker 内置了 DNS 解析
- **但浏览器不在容器内**，所以无法使用服务名

## 解决方案

### 方案一：使用 localhost（当前方案）

```javascript
// api.js
const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000";
```

**优点**:
- ✅ 简单直接
- ✅ 浏览器可以访问
- ✅ 适用于 Docker Compose 和本地开发

**缺点**:
- ❌ 在 K8s 中可能需要配置 Ingress

### 方案二：使用环境变量（运行时配置）

可以在运行时通过环境变量注入 API 地址，但前端是静态文件，需要在构建时注入。

## 修复过程

1. **修改 Dockerfile**: 将 `http://backend:8000` 改为 `http://localhost:8000`
2. **更新 CORS**: 确保允许 `localhost:5173` 访问
3. **重新构建镜像**: 使用新的 API 地址

## 验证方法

打开浏览器开发者工具（F12）：
1. **Network 标签**: 查看 API 请求
2. **Console 标签**: 查看错误信息

**之前（错误）**:
```
GET http://backend:8000/search?q=test net::ERR_NAME_NOT_RESOLVED
```

**现在（正确）**:
```
GET http://localhost:8000/search?q=test 200 OK
```

## 学习要点

1. **理解网络架构**: 浏览器在哪里运行？容器在哪里运行？
2. **服务名 vs localhost**: 容器内用服务名，浏览器用 localhost
3. **端口映射**: Docker 将容器端口映射到宿主机端口
4. **CORS 配置**: 后端需要允许前端域名的跨域请求

## 常见错误

1. ❌ 在浏览器代码中使用容器服务名
2. ❌ CORS 配置不允许前端域名
3. ❌ 端口映射配置错误
4. ❌ 前端和后端不在同一网络

