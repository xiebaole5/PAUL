# 服务器部署指南

## 问题诊断

当前服务器（47.110.72.148）上的代码是旧版本，缺少完整的 API 路由：

**服务器现有路由**：
- `/` - 根路径
- `/health` - 健康检查

**需要的完整路由**（本地最新版本）：
- `/api/generate-video` - 生成视频
- `/api/progress/{task_id}` - 查询进度
- `/api/upload-image` - 上传图片
- `/health` - 健康检查
- `/docs` - API 文档

## 部署方法

### 方法 1：一键部署（推荐）

在本地开发环境执行：

```bash
# 1. 进入项目目录
cd /workspace/projects

# 2. 给部署脚本添加执行权限
chmod +x scripts/deploy_to_server.sh

# 3. 执行一键部署
./scripts/deploy_to_server.sh
```

这个脚本会自动：
1. 打包最新代码
2. 上传到服务器
3. 在服务器上执行部署
4. 验证部署结果

### 方法 2：手动部署

#### 步骤 1：在本地打包代码

```bash
cd /workspace/projects
tar -czf tnho-latest.tar.gz \
  --exclude='.git' \
  --exclude='__pycache__' \
  --exclude='*.pyc' \
  --exclude='logs/*' \
  --exclude='assets/uploads/*' \
  --exclude='node_modules' \
  --exclude='dist' \
  .
```

#### 步骤 2：上传到服务器

```bash
scp tnho-latest.tar.gz root@47.110.72.148:/root/
```

#### 步骤 3：在服务器上部署

SSH 登录到服务器后执行：

```bash
# 1. 备份旧版本
cd /root
mv tnho-video-api tnho-video-api.backup.$(date +%Y%m%d_%H%M%S)

# 2. 解压新代码
mkdir -p tnho-video-api
cd tnho-video-api
tar -xzf /root/tnho-latest.tar.gz

# 3. 创建 .env 文件（如果不存在）
cat > .env << 'EOF'
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
PGDATABASE_URL=postgresql://postgres:postgres@db:5432/tnho_video
EXTERNAL_BASE_URL=https://tnho-fasteners.com
COZE_WORKSPACE_PATH=/app
COZE_INTEGRATION_MODEL_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
COZE_WORKLOAD_IDENTITY_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
EOF

# 4. 重新构建并启动容器
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 5. 查看日志
docker logs -f tnho-video-api
```

#### 步骤 4：更新 Nginx 配置

```bash
# 更新 Nginx 配置
sudo tee /etc/nginx/conf.d/tnho-api.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name tnho-fasteners.com 47.110.72.148;

    client_max_body_size 10M;

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_set_header Host $host;
    }

    location /assets/ {
        proxy_pass http://127.0.0.1:8000/assets/;
        proxy_set_header Host $host;
    }

    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
    }

    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
    }

    location / {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 测试并重载
sudo nginx -t && sudo systemctl reload nginx
```

#### 步骤 5：验证部署

```bash
# 测试健康检查
curl http://localhost/health
curl http://47.110.72.148/health

# 测试 API 文档
curl http://localhost/docs

# 查看容器状态
docker ps | grep tnho

# 查看日志
docker logs -f tnho-video-api
```

## 验证测试

### 1. 健康检查

```bash
curl http://tnho-fasteners.com/health
# 应该返回：{"status":"healthy"}
```

### 2. API 文档

访问：http://tnho-fasteners.com/docs

应该能看到 Swagger UI 界面，列出所有 API 端点。

### 3. 视频生成测试

```bash
# 生成 10 秒视频
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H 'Content-Type: application/json' \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 10,
    "type": "video"
  }'

# 生成 20 秒视频（测试自动分段）
curl -X POST http://tnho-fasteners.com/api/generate-video \
  -H 'Content-Type: application/json' \
  -d '{
    "product_name": "不锈钢螺母",
    "theme": "技术创新",
    "duration": 20,
    "type": "video"
  }'
```

### 4. 查询进度

```bash
# 使用返回的 task_id 查询进度
curl http://tnho-fasteners.com/api/progress/{task_id}
```

## 常用命令

```bash
# 查看容器状态
docker ps | grep tnho

# 查看容器日志
docker logs -f tnho-video-api

# 重启容器
docker-compose restart

# 停止容器
docker-compose down

# 启动容器
docker-compose up -d

# 查看服务状态
systemctl status nginx

# 重新加载 Nginx
sudo systemctl reload nginx

# 测试 Nginx 配置
sudo nginx -t
```

## 故障排查

### 问题 1：容器启动失败

```bash
# 查看详细日志
docker logs tnho-video-api --tail 100

# 重新构建镜像
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 问题 2：API 返回 404

检查后端服务路由是否正确：

```bash
# 直接访问后端
curl http://localhost:8000/health
curl http://localhost:8000/api/generate-video

# 检查 Nginx 配置
cat /etc/nginx/conf.d/tnho-api.conf
```

### 问题 3：视频生成失败

查看后端日志：

```bash
docker logs tnho-video-api -f
```

检查环境变量配置：

```bash
docker exec tnho-video-api env | grep ARK
```

## 目录结构

服务器上的项目结构：

```
/root/tnho-video-api/
├── src/
│   ├── api/
│   │   └── app.py          # FastAPI 主应用
│   ├── agents/
│   │   └── agent.py        # Agent 逻辑
│   ├── tools/
│   │   ├── video_generation_tool.py
│   │   └── video_merge_tool.py
│   └── storage/
│       ├── database/
│       └── memory/
├── config/
│   └── agent_llm_config.json
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── .env                    # 环境变量配置
```

## 环境变量说明

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| ARK_API_KEY | 火山方舟 API 密钥 | 39bf20d0-55b5-4957-baa1-02f4529a3076 |
| ARK_BASE_URL | 火山方舟 API 基础 URL | https://ark.cn-beijing.volces.com/api/v3 |
| PGDATABASE_URL | PostgreSQL 数据库连接 | postgresql://postgres:postgres@db:5432/tnho_video |
| EXTERNAL_BASE_URL | 外部访问 URL | https://tnho-fasteners.com |
| COZE_WORKSPACE_PATH | 工作目录路径 | /app |
