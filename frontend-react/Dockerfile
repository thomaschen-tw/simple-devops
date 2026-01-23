# 阶段 1：构建 React 应用
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
# 注意：VITE_API_BASE_URL 默认值为 http://localhost:8000（在 api.js 中定义）
# 浏览器通过 localhost 访问后端（不是容器服务名）
ARG VITE_API_BASE_URL=http://localhost:8000
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN npm run build

# 阶段 2：使用 nginx 提供静态文件服务
FROM nginx:1.27-alpine AS runtime
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
