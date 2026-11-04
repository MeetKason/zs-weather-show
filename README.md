# 中盛天气秀秀

中盛天气秀秀是面向企业内部使用的私有化数据可视化平台。前端、后端 API、项目数据和上传文件均部署在指定服务器，不依赖外部演示站点、第三方接口文档或公共平台。

## 系统架构

- 前端：Vue 3、TypeScript、Vite、Naive UI、ECharts、VChart、Pinia
- 后端：Java Spring Boot、SQLite、MyBatis-Plus
- 部署：Docker Compose、Nginx 反向代理
- 前端访问端口：`8082`
- 后端服务端口：`8083`，仅供服务器内部访问
- API 前缀：`/api/goview`

浏览器通过前端服务访问同源 API：

```text
浏览器 -> Nginx -> /api/goview -> 后端容器:8083
```

## 本地开发

安装依赖：

```bash
pnpm install
```

启动开发服务：

```bash
pnpm dev
```

本地开发 API 代理配置位于 `.env`：

```bash
VITE_DEV_PATH = 'http://127.0.0.1:8083'
VITE_PRO_PATH = ''
```

生产环境使用同源 API，不在前端配置外部 API 域名。

## 生产构建

```bash
pnpm build
```

构建产物位于 `dist/`，由 Nginx 镜像提供访问。

## API 配置

- API 路径定义：`src/api/path/`
- 请求前缀：`src/settings/httpSetting.ts`
- Axios 封装：`src/api/axios.ts`、`src/api/http.ts`
- 生产 API 前缀固定为：`/api/goview`

修改 API 时应保持同源代理模式，不要在前端写入外部域名或公共演示地址。

## Docker 部署

部署文件位于 `deploy/`：

- `deploy/docker-compose.yml`：前后端服务编排
- `deploy/nginx.conf`：静态文件和 API 反向代理配置
- `Dockerfile`：前端 Nginx 镜像构建文件
- `deploy/data/`：SQLite 数据目录
- `deploy/uploads/`：上传文件目录

仅更新前端时：

```bash
cd deploy
docker compose build frontend
docker compose up -d --no-deps frontend
```

数据库和上传目录属于持久化数据，更新前端时不得覆盖或删除。

## 登录说明

系统默认账号为 `admin`。登录密码由运维人员单独保管，不写入 README，也不在前端页面默认填充。

## 安全约定

- 后端 `8083` 仅监听服务器本机，不对公网开放。
- 前端通过 Nginx 代理访问后端 API。
- 不在源码、构建产物和文档中保留外部 API、演示站点或上游项目跳转地址。
- 生产部署前应检查构建产物中是否包含不应公开的账号、密码或服务地址。
