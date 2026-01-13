# 天虹紧固件视频生成系统 - 完整文档

> 基于 AI 的紧固件产品宣传视频和脚本生成系统
>
> 版本：v1.1.0 | 更新日期：2025-01-13

---

## 📑 目录

1. [项目简介](#项目简介)
2. [快速开始](#快速开始)
3. [功能说明](#功能说明)
4. [部署指南](#部署指南)
5. [小程序使用](#小程序使用)
6. [API 文档](#api-文档)
7. [新功能说明](#新功能说明)
8. [常见问题](#常见问题)
9. [技术支持](#技术支持)

---

## 项目简介

### 核心功能

- 🎬 **AI 视频生成**：自动生成 5-30 秒的宣传视频
- 📝 **脚本生成**：生成专业营销脚本（含场景、文案、音效）
- 📷 **产品图片上传**：支持上传产品照片，生成更精准的视频
- 🎨 **多主题选择**：品质保证、技术创新、工业应用、品牌形象
- ⏱️ **时长定制**：5/10/15/20/25/30 秒六种时长
- 📱 **微信小程序**：便捷的用户交互界面

### 技术栈

**后端**：
- Python 3.9+
- FastAPI
- LangChain 1.0
- LangGraph 1.0
- 火山方舟 doubao-seedance（视频生成）
- 火山方舟 doubao-seed（LLM）

**前端**：
- 微信小程序原生开发
- WXML、WXSS、JavaScript

### 项目结构

```
tnho-video-generator/
├── src/                    # 后端源代码
│   ├── agents/            # Agent 代码
│   ├── tools/             # 工具代码
│   ├── storage/           # 存储模块
│   ├── api/               # API 服务
│   └── main.py
├── miniprogram/           # 微信小程序前端
├── config/                # 配置文件
├── scripts/               # 脚本工具
├── docs/                  # 文档
├── tests/                 # 测试
├── requirements.txt       # Python 依赖
└── README.md
```

---

## 快速开始

### 1. 解压项目

```bash
tar -xzf tnho-video-generator_v*.tar.gz
cd tnho-video-generator/
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 配置 API Key

创建 `.env` 文件（在项目根目录）：

```bash
# 必填：火山方舟 API Key
ARK_API_KEY=your_api_key_here

# 可选：对象存储配置
COZE_S3_ENDPOINT=https://s3.example.com
COZE_S3_ACCESS_KEY=your_access_key
COZE_S3_SECRET_KEY=your_secret_key
COZE_S3_BUCKET=your_bucket_name
```

**获取 API Key**：
- 登录 [火山方舟控制台](https://console.volcengine.com/ark)
- 创建应用并获取 API Key

### 4. 启动后端服务

```bash
# Linux/Mac
chmod +x scripts/start_backend.sh
./scripts/start_backend.sh

# Windows
scripts\start_backend.bat
```

服务启动后：
- API 地址：http://localhost:8000
- 健康检查：http://localhost:8000/health
- API 文档：http://localhost:8000/docs

### 5. 启动小程序

#### 开发环境

1. 下载并安装 [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
2. 打开微信开发者工具
3. 选择「导入项目」
4. 选择 `miniprogram` 目录
5. AppID：开发阶段可选择「测试号」
6. 点击「导入」

#### 配置开发环境

在微信开发者工具中：
1. 点击右上角「详情」
2. 勾选「不校验合法域名、web-view、TLS 版本以及 HTTPS 证书」

#### 修改后端地址

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 开发环境：使用本地地址
    apiBaseUrl: 'http://localhost:8000'

    // 生产环境：使用实际部署地址
    // apiBaseUrl: 'https://your-domain.com'
  }
})
```

#### 开始使用

1. 在小程序中输入产品名称（如「高强度螺栓」）
2. 选择主题（品质保证、技术创新等）
3. 选择时长（5-30秒）
4. 点击「生成视频」
5. 等待 30-60 秒，查看生成的视频

---

## 功能说明

### 视频生成功能

**功能描述**：AI 自动生成紧固件产品宣传视频

**操作步骤**：
1. 输入产品名称
2. 选择宣传主题
3. 选择视频时长
4. 点击"生成视频"
5. 等待 30-60 秒

**可选功能**：
- 上传产品图片
- 描述使用场景

**支持主题**：
- 品质保证
- 技术创新
- 工业应用
- 品牌形象

**支持时长**：
- 5秒、10秒、15秒、20秒、25秒、30秒

### 脚本生成功能

**功能描述**：生成营销视频脚本，包含场景描述、文案/旁白、音效

**操作步骤**：
1. 输入产品名称
2. 选择宣传主题
3. 选择视频时长
4. 点击"生成脚本"
5. 查看生成的脚本内容
6. 复制脚本或分享

**脚本内容**：
- 场景描述
- 文案/旁白
- 音效建议

---

## 部署指南

### 本地部署

#### 环境要求

- Python 3.9+
- Node.js 16+ (用于微信开发者工具)
- 微信开发者工具
- 火山方舟 API Key

#### 安装依赖

```bash
pip install -r requirements.txt
```

#### 启动服务

**方式一：使用启动脚本（推荐）**

```bash
# Linux/Mac
chmod +x scripts/start_backend.sh
./scripts/start_backend.sh

# Windows
scripts\start_backend.bat
```

**方式二：手动启动**

```bash
# 开发模式
cd src/api
python app.py

# 生产模式
uvicorn src.api.app:app --host 0.0.0.0 --port 8000 --workers 4
```

### 云服务器部署

#### 系统要求

推荐配置：
- CPU: 2核
- 内存: 4G
- 系统: Ubuntu 20.04 LTS

#### 部署步骤

1. **购买云服务器**

2. **安装 Python 环境**

```bash
# 更新系统
sudo apt-get update

# 安装 Python 3.9
sudo apt-get install python3.9 python3-pip python3-venv

# 创建虚拟环境
python3.9 -m venv /opt/tnho-video
source /opt/tnho-video/bin/activate
```

3. **部署项目**

```bash
# 上传项目文件
scp tnho-video-generator_v*.tar.gz user@server:/opt/

# 解压
cd /opt
tar -xzf tnho-video-generator_v*.tar.gz

# 安装依赖
cd tnho-video-generator
pip install -r requirements.txt
```

4. **使用 Nginx 反向代理**

```bash
# 安装 Nginx
sudo apt-get install nginx

# 配置 Nginx
sudo nano /etc/nginx/sites-available/tnho-api
```

Nginx 配置：

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

启用配置：

```bash
sudo ln -s /etc/nginx/sites-available/tnho-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

5. **配置 HTTPS**

```bash
# 安装 Certbot
sudo apt-get install certbot python3-certbot-nginx

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com
```

6. **使用 PM2 管理进程**

```bash
# 安装 PM2
npm install -g pm2

# 创建 ecosystem.config.js
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'tnho-api',
    script: 'uvicorn',
    args: 'src.api.app:app --host 127.0.0.1 --port 8000',
    cwd: '/opt/tnho-video-generator',
    instances: 2,
    exec_mode: 'cluster',
    autorestart: true,
    max_memory_restart: '1G',
    env: {
      ARK_API_KEY: 'your_api_key_here'
    }
  }]
}
EOF

# 启动服务
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### Docker 部署

#### 创建 Dockerfile

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

#### 创建 docker-compose.yml

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

#### 启动服务

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

---

## 小程序使用

### 开发环境配置

#### 1. 下载微信开发者工具

访问 [微信开发者工具官网](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)，下载并安装适合你操作系统的版本。

#### 2. 导入项目

1. 打开微信开发者工具
2. 选择「导入项目」
3. 项目目录：选择 `miniprogram` 文件夹
4. AppID：填写你的小程序 AppID（开发阶段可选择「测试号」）
5. 项目名称：`天虹视频生成器`
6. 点击「导入」

#### 3. 配置开发环境

在微信开发者工具中：
1. 点击右上角「详情」
2. 在「本地设置」中勾选：
   - ☑️ 不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书
3. 这样可以使用本地后端服务进行调试

#### 4. 修改后端 API 地址

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 开发环境：使用本地地址
    apiBaseUrl: 'http://localhost:8000'

    // 生产环境：使用实际部署地址
    // apiBaseUrl: 'https://your-domain.com'
  }
})
```

### 调试技巧

#### 1. 查看日志

在微信开发者工具中：
- 点击「调试器」打开调试面板
- 查看 Console 输出调试信息
- 查看 Network 监控网络请求

#### 2. 模拟数据

在 `miniprogram/pages/index/index.js` 的 `onLoad` 方法中，可以添加测试数据：

```javascript
onLoad(options) {
  // 测试数据
  this.setData({
    productName: '高强度螺栓',
    selectedTheme: '品质保证',
    selectedDuration: 20
  })
}
```

#### 3. 清除缓存

如果遇到数据缓存问题：
1. 点击工具栏「清缓存」
2. 选择「清除数据缓存」和「清除文件缓存」
3. 重新编译项目

### 生产环境发布

#### 1. 配置服务器域名

在 [微信公众平台](https://mp.weixin.qq.com/)：

1. 登录后台
2. 进入「开发」-「开发管理」-「开发设置」
3. 在「服务器域名」中添加：
   - request 合法域名：`https://your-domain.com`
   - uploadFile 合法域名：`https://your-domain.com`
   - downloadFile 合法域名：`https://your-domain.com`

#### 2. 修改生产环境配置

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 生产环境：使用实际域名
    apiBaseUrl: 'https://your-domain.com'
  }
})
```

编辑 `miniprogram/project.config.json`：

```json
{
  "appid": "your_real_appid_here",
  "setting": {
    "urlCheck": true  // 生产环境必须开启域名检查
  }
}
```

#### 3. 上传代码

1. 在微信开发者工具中点击「上传」
2. 填写版本号（如：1.0.0）
3. 填写项目备注（如：首次发布）

#### 4. 提交审核

1. 登录微信公众平台
2. 进入「版本管理」-「开发版本」
3. 选择刚上传的版本，点击「提交审核」
4. 填写审核信息：
   - 功能页面：选择「首页」
   - 类目：选择「工具」-「效率」
   - 服务类目：选择合适的类目

#### 5. 发布

审核通过后：
1. 进入「版本管理」-「审核版本」
2. 点击「发布」

---

## API 文档

### 基础信息

- **Base URL**: `http://localhost:8000` (开发环境)
- **Base URL**: `https://your-domain.com` (生产环境)

### 1. 健康检查

**接口地址**：`GET /health`

**请求示例**：

```bash
curl http://localhost:8000/health
```

**响应示例**：

```json
{
  "status": "ok"
}
```

### 2. 图片上传

**接口地址**：`POST /api/upload-image`

**请求方式**：`multipart/form-data`

**请求参数**：
- `file`: 图片文件（必填）
  - 支持 JPG、PNG 格式
  - 最大 5MB

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/path/to/your/image.jpg"
```

**响应示例**：

```json
{
  "success": true,
  "message": "图片上传成功",
  "image_url": "http://localhost:8000/assets/uploads/xxx.jpg",
  "filename": "xxx.jpg"
}
```

**错误示例**：

```json
{
  "success": false,
  "message": "仅支持 JPG、PNG 格式的图片"
}
```

### 3. 视频生成

**接口地址**：`POST /api/generate-video`

**请求方式**：`application/json`

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| product_name | string | 是 | 产品名称 |
| theme | string | 否 | 主题（默认：品质保证） |
| duration | int | 否 | 视频时长，单位秒（默认：20） |
| type | string | 否 | 生成类型：video/script（默认：video） |
| scenario | string | 否 | 使用场景描述 |
| product_image_url | string | 否 | 产品图片 URL |
| session_id | string | 否 | 会话 ID |

**可用主题**：
- 品质保证
- 技术创新
- 工业应用
- 品牌形象

**可用时长**：
- 5、10、15、20、25、30 秒

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "video",
    "scenario": "用于汽车制造中的高强度连接场景",
    "product_image_url": "http://localhost:8000/assets/uploads/xxx.jpg"
  }'
```

**响应示例**：

```json
{
  "success": true,
  "message": "视频生成成功",
  "video_url": "https://example.com/video.mp4",
  "session_id": "session_xxx",
  "type": "video"
}
```

**错误示例**：

```json
{
  "success": false,
  "message": "主题无效，可选主题：品质保证, 技术创新, 工业应用, 品牌形象"
}
```

### 4. 脚本生成

**接口地址**：`POST /api/generate-video`

**请求方式**：`application/json`

**请求参数**：同视频生成，但 `type` 设置为 `script`

**请求示例**：

```bash
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "script",
    "scenario": "用于汽车制造中的高强度连接场景"
  }'
```

**响应示例**：

```json
{
  "success": true,
  "message": "脚本生成成功",
  "script_content": "## 视频脚本\n\n### 场景1：产品特写\n...",
  "session_id": "session_xxx",
  "type": "script"
}
```

### 5. 静态文件访问

**接口地址**：`GET /assets/uploads/{filename}`

**说明**：访问上传的图片文件

**示例**：

```
http://localhost:8000/assets/uploads/xxx.jpg
```

---

## 新功能说明

### v1.1.0 新增功能（2025-01-13）

#### 1. 产品图片上传

**功能描述**：用户可以上传紧固件产品的照片，AI 将基于图片生成更精准的宣传视频。

**使用方法**：

1. 在小程序中点击"📷 点击上传产品图片"
2. 选择相册或拍照
3. 等待上传完成
4. 图片显示后可以预览或删除

**限制**：
- 支持 JPG、PNG 格式
- 最大文件大小 5MB
- 可随时删除重新上传

**API 调用**：

```bash
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@/path/to/your/image.jpg"
```

#### 2. 使用场景描述

**功能描述**：用户可以详细描述产品的使用场景，AI 将根据场景描述生成更贴合需求的视频。

**使用方法**：

1. 在小程序的场景描述框中输入文字
2. 最多 200 字
3. 实时显示字符计数

**示例场景**：

```
示例 1：用于汽车制造中的高强度连接场景，承受高载荷和振动环境
示例 2：用于太阳能光伏支架安装，长期暴露在户外环境
示例 3：用于桥梁建设中的关键连接部位，要求抗腐蚀能力强
```

**API 调用**：

```bash
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "高强度螺栓",
    "theme": "品质保证",
    "duration": 20,
    "type": "video",
    "scenario": "用于汽车制造中的高强度连接场景"
  }'
```

#### 3. 组合使用

**最佳实践**：同时使用图片上传和场景描述，可以获得最佳效果。

**完整示例**：

```bash
# 1. 上传图片
curl -X POST http://localhost:8000/api/upload-image \
  -F "file=@bolt.jpg" \
  | jq -r '.image_url' > image_url.txt

# 2. 生成视频（使用图片和场景）
IMAGE_URL=$(cat image_url.txt)
curl -X POST http://localhost:8000/api/generate-video \
  -H "Content-Type: application/json" \
  -d "{
    \"product_name\": \"高强度螺栓\",
    \"theme\": \"品质保证\",
    \"duration\": 20,
    \"type\": \"video\",
    \"scenario\": \"用于汽车制造中的高强度连接场景，承受高载荷和振动环境\",
    \"product_image_url\": \"$IMAGE_URL\"
  }"
```

### 使用建议

#### 什么时候应该上传产品图片？

✅ **推荐上传**：
- 需要精准展示产品外观
- 产品有特殊设计或特征
- 希望视频中的产品更符合实际

❌ **可以不传**：
- 只需要概念性的展示
- 产品通用性较强
- 快速测试功能

#### 什么时候应该填写场景描述？

✅ **推荐填写**：
- 产品用于特定行业
- 有明确的应用场景
- 需要突出产品性能参数

❌ **可以不填**：
- 只需要通用性展示
- 快速测试功能

---

## 常见问题

### Q1: 后端启动失败

**检查清单**：
1. Python 版本是否为 3.9+
   ```bash
   python --version
   ```

2. 依赖是否安装完整
   ```bash
   pip list | grep fastapi
   pip list | grep langchain
   ```

3. API Key 是否正确配置
   ```bash
   echo $ARK_API_KEY
   ```

4. 端口 8000 是否被占用
   ```bash
   lsof -i :8000
   ```

**解决方法**：
- 安装正确版本的 Python
- 重新安装依赖：`pip install -r requirements.txt`
- 检查 API Key 配置
- 停止占用端口的进程或修改端口

### Q2: 小程序无法连接后端

**检查清单**：
1. 后端服务是否已启动
   ```bash
   curl http://localhost:8000/health
   ```

2. 开发环境：在微信开发者工具中启用「不校验合法域名」

3. `apiBaseUrl` 配置是否正确
   ```javascript
   // miniprogram/app.js
   apiBaseUrl: 'http://localhost:8000'
   ```

4. 是否在同一个网络环境（本地调试时）

**解决方法**：
- 确认后端服务已启动
- 开发环境：启用「不校验合法域名」
- 生产环境：配置 HTTPS 域名
- 检查 `apiBaseUrl` 配置
- 真机调试时使用局域网 IP

### Q3: 视频生成失败

**可能原因**：
- API Key 无效或额度不足
- 网络连接问题
- 模型调用超时
- 参数不符合要求

**解决方法**：
1. 检查 API Key 配置
   ```bash
   echo $ARK_API_KEY
   ```

2. 查看后端日志
   ```bash
   # 如果使用 PM2
   pm2 logs tnho-api
   ```

3. 检查网络连接
   ```bash
   ping ark.cn-beijing.volces.com
   ```

4. 增加超时时间
   - 修改 `config/agent_llm_config.json` 中的 `timeout` 参数

5. 检查参数是否符合要求
   - 时长：5-30 秒
   - 主题：品质保证、技术创新、工业应用、品牌形象

### Q4: 小程序审核被拒

**常见原因**：
- 未配置服务器域名白名单
- 内容违规
- 功能描述不准确
- 类目选择错误

**解决方案**：
1. 确保已配置合法域名
   - 登录微信公众平台
   - 配置 request、uploadFile、downloadFile 域名

2. 检查小程序内容是否符合规范
   - 避免敏感词汇
   - 确保内容健康向上

3. 完善小程序功能描述
   - 准确描述功能
   - 选择正确的类目

### Q5: 图片上传失败

**可能原因**：
- 图片格式不支持
- 文件大小超过限制
- 网络问题
- 后端服务异常

**解决方法**：
1. 检查图片格式
   - 仅支持 JPG、PNG 格式

2. 检查文件大小
   - 最大 5MB
   - 压缩后重新上传

3. 检查网络连接
   - 确保网络稳定

4. 检查后端服务
   - 确认服务正常运行
   - 查看错误日志

### Q6: 生成的视频不包含 TNHO 商标

**说明**：
- 商标由 AI 模型根据提示词自动生成
- 由于 AI 生成的不确定性，商标可能不总是明显

**解决方法**：
- 多次尝试生成
- 在提示词中强调商标
- 使用"品牌形象"主题

**注意**：
- 商标拼写为 TNHO（天虹），不是 TOHO
- 代码中已经多次强调拼写，但 AI 生成仍可能有误差

### Q7: 视频生成时间过长

**说明**：
- 正常生成时间：30-60 秒
- 受网络状况、模型负载影响

**解决方法**：
1. 检查网络连接
2. 稍微缩短视频时长
3. 选择非高峰时段生成
4. 如超过 5 分钟未完成，可能是服务异常，请检查日志

---

## 技术支持

### 文档资源

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - 完整部署指南
- [MINIPROGRAM_README.md](MINIPROGRAM_README.md) - 小程序使用说明
- [NEW_FEATURES_GUIDE.md](NEW_FEATURES_GUIDE.md) - 新功能详细说明
- [PACKAGE_GUIDE.md](PACKAGE_GUIDE.md) - 打包和下载指南

### 配置说明

### Agent 配置

`config/agent_llm_config.json`：

```json
{
  "config": {
    "model": "doubao-seed-1-6-251015",
    "temperature": 1,
    "max_completion_tokens": 50000,
    "timeout": 600
  },
  "sp": "Agent 系统提示词..."
}
```

**参数说明**：
- `model`: 使用的模型名称
- `temperature`: 随机性控制（0-2）
- `max_completion_tokens`: 最大生成 tokens
- `timeout`: 超时时间（秒）
- `sp`: 系统提示词

### 小程序配置

`miniprogram/project.config.json`：

```json
{
  "appid": "your_appid_here",
  "projectname": "tnho-video-generator",
  "description": "天虹紧固件视频生成小程序"
}
```

**参数说明**：
- `appid`: 小程序 AppID
- `projectname`: 项目名称
- `description`: 项目描述

### 环境变量

`.env` 文件：

```bash
# 必填：火山方舟 API Key
ARK_API_KEY=your_api_key_here

# 可选：对象存储配置
COZE_S3_ENDPOINT=https://s3.example.com
COZE_S3_ACCESS_KEY=your_access_key
COZE_S3_SECRET_KEY=your_secret_key
COZE_S3_BUCKET=your_bucket_name
```

**参数说明**：
- `ARK_API_KEY`: 火山方舟 API Key（必填）
- `COZE_S3_ENDPOINT`: 对象存储地址
- `COZE_S3_ACCESS_KEY`: 对象存储访问密钥
- `COZE_S3_SECRET_KEY`: 对象存储密钥
- `COZE_S3_BUCKET`: 对象存储桶名称

### 测试

#### 后端测试

```bash
# 运行单元测试
pytest tests/

# 运行 API 测试
pytest tests/test_api.py

# 运行图片上传测试
pytest tests/test_image_upload.py
```

#### 手动测试

1. 启动后端服务
2. 打开微信开发者工具
3. 测试视频生成功能
4. 测试脚本生成功能
5. 测试图片上传功能

### 日志查看

#### 开发环境

```bash
# 查看实时日志
./scripts/start_backend.sh

# 查看错误日志
tail -f error.log
```

#### 生产环境（PM2）

```bash
# 查看实时日志
pm2 logs tnho-api

# 查看错误日志
pm2 logs tnho-api --err

# 查看历史日志
pm2 logs tnho-api --lines 100
```

#### 生产环境（Docker）

```bash
# 查看实时日志
docker-compose logs -f api

# 查看最近日志
docker-compose logs --tail 100 api
```

---

## 更新日志

### v1.1.0 (2025-01-13)

- ✅ 新增产品图片上传功能
- ✅ 新增使用场景描述功能
- ✅ 更新视频生成工具，支持图片和场景参数
- ✅ 新增图片上传 API 接口
- ✅ 更新小程序前端，添加图片上传和场景描述界面
- ✅ 完善文档和测试

### v1.0.0 (2025-01-12)

- ✅ 初始版本发布
- ✅ AI 视频生成（5-30秒）
- ✅ 脚本生成功能
- ✅ 4种主题选择
- ✅ 微信小程序前端
- ✅ FastAPI 后端服务
- ✅ 完整文档和部署指南

---

## 附录

### 工具函数

#### 视频生成工具

**函数名**：`generate_fastener_promo_video`

**参数**：
- `product_name`: 产品名称（必填）
- `theme`: 主题（默认：品质保证）
- `duration`: 时长（默认：20秒）
- `scenario`: 使用场景描述（可选）
- `product_image_url`: 产品图片 URL（可选）

**返回**：JSON 格式的视频生成结果

**示例**：

```python
from src.tools.video_generation_tool import generate_fastener_promo_video

result = generate_fastener_promo_video(
    product_name="高强度螺栓",
    theme="品质保证",
    duration=20,
    scenario="用于汽车制造中的高强度连接场景",
    product_image_url="http://example.com/product.jpg"
)
```

#### 脚本生成工具

**函数名**：`generate_fastener_promo_script`

**参数**：
- `product_name`: 产品名称（必填）
- `theme`: 主题（默认：品质保证）
- `duration`: 时长（默认：20秒）

**返回**：JSON 格式的脚本内容

**示例**：

```python
from src.tools.video_script_generator import generate_fastener_promo_script

result = generate_fastener_promo_script(
    product_name="高强度螺栓",
    theme="品质保证",
    duration=20
)
```

### 商标说明

**商标拼写**：TNHO（天虹）

**注意事项**：
- 商标是 TNHO，不是 TOHO
- 代码中已多次强调拼写
- AI 生成仍可能有误差，建议多次尝试

### 联系方式

如有问题，请联系技术支持。

---

**文档版本**: v1.1.0
**最后更新**: 2025-01-13
**维护者**: 天虹紧固件技术团队
