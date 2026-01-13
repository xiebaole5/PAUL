# 天虹紧固件视频生成小程序 - 完整部署指南

## 📋 目录
- [项目概述](#项目概述)
- [前置要求](#前置要求)
- [后端部署](#后端部署)
- [小程序部署](#小程序部署)
- [常见问题](#常见问题)

---

## 项目概述

本项目为浙江天虹紧固件有限公司开发的AI宣传视频生成系统，包含：
- **后端服务**：基于 FastAPI + LangChain 的 AI Agent
- **微信小程序**：用户交互界面
- **视频生成**：使用火山方舟 doubao-seedance 模型

---

## 前置要求

### 环境要求
- Python 3.9+
- Node.js 16+ (用于微信开发者工具)
- 微信开发者工具
- 火山方舟 API Key

### 必需工具
```bash
# 安装 Python 依赖
pip install -r requirements.txt

# 下载微信开发者工具
# https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html
```

---

## 后端部署

### 1. 配置环境变量

创建 `.env` 文件（如果不存在）：

```bash
# API Key 配置（必须）
ARK_API_KEY=your_api_key_here

# 对象存储配置（可选，用于上传生成的视频）
COZE_S3_ENDPOINT=https://s3.example.com
COZE_S3_ACCESS_KEY=your_access_key
COZE_S3_SECRET_KEY=your_secret_key
COZE_S3_BUCKET=your_bucket_name
```

**重要**：替换 `ARK_API_KEY` 为你的火山方舟 API Key。

### 2. 安装依赖

```bash
cd /workspace/projects
pip install -r requirements.txt
```

### 3. 启动后端服务

#### 方式一：使用启动脚本（推荐）

```bash
# Linux/Mac
chmod +x scripts/start_backend.sh
./scripts/start_backend.sh

# Windows
scripts\start_backend.bat
```

#### 方式二：手动启动

```bash
# 开发模式
cd src/api
python app.py

# 生产模式
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --workers 4
```

启动成功后，服务将在 `http://localhost:8000` 运行。

### 4. 验证服务

```bash
# 健康检查
curl http://localhost:8000/health

# 预期输出：
# {"status":"ok"}
```

---

## 小程序部署

### 1. 配置小程序基本信息

编辑 `miniprogram/project.config.json`：

```json
{
  "appid": "your_appid_here",  // 替换为你的小程序 AppID
  "projectname": "tnho-video-generator"
}
```

**获取 AppID**：
1. 登录 [微信公众平台](https://mp.weixin.qq.com/)
2. 注册小程序账号
3. 在「开发」-「开发管理」中获取 AppID

### 2. 配置后端 API 地址

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 修改为你的后端服务地址
    // 开发环境：使用本地地址（需启用开发者工具的「不校验合法域名」）
    apiBaseUrl: 'http://localhost:8000'

    // 生产环境：使用实际部署地址
    // apiBaseUrl: 'https://your-domain.com'
  }
})
```

### 3. 使用微信开发者工具打开小程序

1. 打开微信开发者工具
2. 选择「导入项目」
3. 选择项目目录：`miniprogram/`
4. 填入 AppID
5. 点击「导入」

### 4. 开发调试

#### 开发环境配置

在微信开发者工具中：
1. 点击右上角「详情」
2. 勾选「不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书」
3. 这样可以使用 `http://localhost:8000` 进行调试

#### 测试功能

1. 在小程序中输入产品名称（如「高强度螺栓」）
2. 选择主题（品质保证、技术创新等）
3. 选择时长（5-30秒）
4. 点击「生成视频」
5. 等待 30-60 秒，查看生成的视频

### 5. 生产环境部署

#### 域名配置

1. 准备一个 HTTPS 域名（需要备案）
2. 在微信公众平台配置服务器域名：
   - 登录后台
   - 进入「开发」-「开发管理」-「开发设置」
   - 在「服务器域名」中添加：
     - request 合法域名：`https://your-domain.com`
     - uploadFile 合法域名：`https://your-domain.com`
     - downloadFile 合法域名：`https://your-domain.com`

3. 修改 `miniprogram/app.js` 中的 `apiBaseUrl` 为实际域名

#### 发布小程序

1. 在微信开发者工具中点击「上传」
2. 填写版本号和项目备注
3. 登录微信公众平台
4. 进入「版本管理」-「开发版本」
5. 选择版本，点击「提交审核」
6. 审核通过后，点击「发布」

---

## 云服务器部署（生产环境）

### 使用 Nginx 反向代理

1. 安装 Nginx：
```bash
sudo apt-get install nginx
```

2. 配置 Nginx (`/etc/nginx/sites-available/tnho-api`)：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

3. 启用配置：
```bash
sudo ln -s /etc/nginx/sites-available/tnho-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

4. 配置 HTTPS（使用 Let's Encrypt）：
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 使用 PM2 管理进程

1. 安装 PM2：
```bash
npm install -g pm2
```

2. 创建 `ecosystem.config.js`：
```javascript
module.exports = {
  apps: [{
    name: 'tnho-api',
    script: 'uvicorn',
    args: 'src.api.app:app --host 0.0.0.0 --port 8000',
    cwd: '/workspace/projects',
    instances: 2,
    exec_mode: 'cluster',
    autorestart: true,
    max_memory_restart: '1G',
    env: {
      ARK_API_KEY: 'your_api_key_here'
    }
  }]
}
```

3. 启动服务：
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

---

## Docker 部署（可选）

### 1. 创建 Dockerfile

```dockerfile
FROM python:3.9-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目文件
COPY . .

# 暴露端口
EXPOSE 8000

# 启动服务
CMD ["uvicorn", "src.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 2. 创建 docker-compose.yml

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - ARK_API_KEY=${ARK_API_KEY}
      - COZE_S3_ENDPOINT=${COZE_S3_ENDPOINT}
      - COZE_S3_ACCESS_KEY=${COZE_S3_ACCESS_KEY}
      - COZE_S3_SECRET_KEY=${COZE_S3_SECRET_KEY}
      - COZE_S3_BUCKET=${COZE_S3_BUCKET}
    restart: unless-stopped
```

### 3. 启动服务

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## 常见问题

### Q1: 后端启动失败

**检查清单**：
- Python 版本是否为 3.9+
- 依赖是否安装完整：`pip list | grep langchain`
- API Key 是否正确配置
- 端口 8000 是否被占用

### Q2: 小程序无法连接后端

**解决方案**：
- 确认后端服务已启动：访问 `http://localhost:8000/health`
- 开发环境：在微信开发者工具中启用「不校验合法域名」
- 生产环境：确认已配置 HTTPS 域名
- 检查 `miniprogram/app.js` 中的 `apiBaseUrl` 是否正确

### Q3: 视频生成失败

**可能原因**：
- API Key 无效或额度不足
- 网络连接问题
- 模型调用超时

**解决方案**：
- 检查 API Key 配置
- 查看 `src/api/app.py` 日志输出
- 增加超时时间配置

### Q4: 小程序审核被拒

**常见原因**：
- 未配置服务器域名白名单
- 内容违规
- 功能描述不准确

**解决方案**：
- 确保已配置合法域名
- 检查小程序内容是否符合规范
- 完善小程序功能描述和类目

---

## 技术支持

如有问题，请联系技术支持或查看：
- 后端文档：`src/api/README.md`
- 小程序文档：`miniprogram/README.md`
- Agent 配置：`config/agent_llm_config.json`

---

## 更新日志

### v1.0.0 (2025-01-XX)
- ✅ 初始版本发布
- ✅ 支持视频生成（5-30秒）
- ✅ 支持脚本生成
- ✅ 4种主题选择
- ✅ 微信小程序前端
- ✅ FastAPI 后端服务

---

**祝部署顺利！🎉**
