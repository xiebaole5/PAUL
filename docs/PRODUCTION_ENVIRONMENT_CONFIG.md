# 生产环境配置摘要

## 域名备案状态

✅ **域名已备案完成**

- 域名: tnho-fasteners.com
- 备案主体: 天虹紧固件有限公司（假设）
- 备案号: （需要填写实际备案号）

## 小程序配置

✅ **已更新为使用域名**

```javascript
// miniprogram/app.js
globalData: {
  apiUrl: 'https://tnho-fasteners.com',
}
```

**小程序信息**:
- AppID: wx464504ca7e01b3b1
- API 地址: https://tnho-fasteners.com
- 服务器域名配置:
  - request: https://tnho-fasteners.com
  - uploadFile: https://tnho-fasteners.com
  - downloadFile: https://tnho-fasteners.com

## 企业微信配置

✅ **已更新为使用域名**

```bash
# 企业微信机器人配置
- 机器人名称: TNHO全能营销助手
- 回调 URL: https://tnho-fasteners.com/api/wechat/callback
- Token: （从 .env 读取）
- EncodingAESKey: （从 .env 读取）
- Corp ID: （从 .env 读取）
```

**企业微信能力**:
- 视频生成（doubao-seedance-1-5-pro-251215）
- 图片生成（doubao-seedream）
- 文案生成（doubao-seed-1-8-251228）
- 语音合成（doubao-voice）

## 服务器配置

✅ **服务运行正常**

- **服务器 IP**: 115.190.192.22
- **服务端口**: 8080
- **运行用户**: root
- **服务状态**: 运行中 (PID: 1088)

**服务启动命令**:
```bash
./scripts/service.sh start
```

**服务停止命令**:
```bash
./scripts/service.sh stop
```

**服务重启命令**:
```bash
./scripts/service.sh restart
```

**查看日志**:
```bash
./scripts/service.sh logs
```

## 数据库配置

```bash
# .env 配置
PGDATABASE_URL=postgresql://user_7594343940086612003:***@cp-stoic-storm-cc421d34.pg2.aidap-global.cn-beijing.volces.com:5432/Database_1768197453926?sslmode=require&channel_binding=require
```

**数据库连接池配置**:
- pool_size: 10
- max_overflow: 10
- pool_timeout: 30s
- statement_timeout: 30s

## 对象存储配置

**服务提供商**: 阿里云 OSS

```bash
# 环境变量
COZE_BUCKET_ENDPOINT_URL=（从环境变量读取）
COZE_BUCKET_NAME=（从环境变量读取）
```

**上传路径示例**:
- 视频文件: `videos/tnho_promo_video_20250114_151600_a1b2c3d4.mp4`
- 图片文件: `images/wechat_image_20250114_151600_a1b2c3d4.png`
- 语音文件: `voices/wechat_voice_20250114_151600_a1b2c3d4.mp3`

## 模型配置

**火山方舟 API**:
```bash
# .env 配置
ARK_API_KEY=e1533511-efae-4131-aea9-b573a1be4ecf
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
```

**使用的模型**:
- 视频生成: doubao-seedance-1-5-pro-251215
- 文本处理: doubao-seed-1-8-251228
- 图片生成: doubao-seedream
- 语音合成: doubao-voice

## Cloudflare 配置

⚠️ **需要手动更新源站 IP**

**当前配置**:
- 源站 IP（旧）: 47.110.72.148
- 源站 IP（新）: 115.190.192.22
- SSL/TLS 模式: Flexible
- Bot Fight Mode: Off

**配置步骤**:
1. 登录 Cloudflare 控制台
2. 导航到 DNS -> Records
3. 找到 A 记录（@）
4. 将 Content 更新为 115.190.192.22
5. 保存并等待 DNS 传播（5-10 分钟）

## 接口列表

### 健康检查
```
GET /health
返回: {"status":"ok"}
```

### 小程序接口

**生成脚本**
```
POST /api/generate-script
Content-Type: application/json

{
  "theme": "品质保证",
  "duration": 20,
  "scenario": "产品展示"
}
```

**生成视频**
```
POST /api/generate-video
Content-Type: application/json

{
  "theme": "技术创新",
  "duration": 20,
  "scenario": "研发场景",
  "product_image_url": "https://example.com/image.jpg"
}
```

**上传图片**
```
POST /api/upload-image
Content-Type: multipart/form-data

file: (binary data)
```

**查询进度**
```
GET /api/progress/{task_id}
返回: {"task_id":"xxx","status":"completed","progress":100}
```

### 企业微信接口

**URL 验证**
```
GET /api/wechat/callback?msg_signature=xxx&timestamp=xxx&nonce=xxx&echostr=xxx
返回: 验证字符串
```

**接收消息**
```
POST /api/wechat/callback?msg_signature=xxx&timestamp=xxx&nonce=xxx
Content-Type: text/xml

<xml>
  <ToUserName>...</ToUserName>
  <FromUserName>...</FromUserName>
  <CreateTime>...</CreateTime>
  <MsgType>text</MsgType>
  <Content>生成一个视频</Content>
</xml>
```

**测试接口**
```
GET /api/wechat/test
返回: {"status":"ok","message":"企业微信接口正常",...}
```

## 依赖版本

```
fastapi==0.115.6
uvicorn==0.34.0
langchain==0.3.13
langchain-openai==0.2.14
langgraph==0.2.59
requests==2.32.3
moviepy==2.2.1
coze-coding-dev-sdk==0.1.1
python-multipart==0.0.21
cryptography==44.0.0
psycopg2-binary==2.9.10
python-dotenv==1.0.1
```

## 快速部署检查清单

### 首次部署

- [ ] 在 Cloudflare 控制台更新源站 IP 为 115.190.192.22
- [ ] 等待 DNS 传播完成（5-10 分钟）
- [ ] 测试 HTTPS 访问: curl https://tnho-fasteners.com/health
- [ ] 在企业微信后台配置回调 URL: https://tnho-fasteners.com/api/wechat/callback
- [ ] 在小程序后台配置合法域名: https://tnho-fasteners.com
- [ ] 测试小程序功能（使用真机）
- [ ] 测试企业微信机器人功能

### 日常运维

- [ ] 监控服务状态: `./scripts/service.sh status`
- [ ] 查看服务日志: `./scripts/service.sh logs`
- [ ] 检查数据库连接
- [ ] 检查对象存储空间
- [ ] 监控 API 调用量
- [ ] 检查 Cloudflare 安全日志

## 故障排查

### 服务无法启动

```bash
# 查看服务日志
./scripts/service.sh logs

# 检查端口占用
netstat -tuln | grep 8080

# 手动启动测试
python3 app.py
```

### API 返回 403

```bash
# 检查 Cloudflare Bot Fight Mode
# 确保已关闭 Bot Fight Mode

# 检查源站 IP 配置
# 确保指向 115.190.192.22
```

### 小程序请求失败

```bash
# 检查小程序配置
# 确保 API 地址为 https://tnho-fasteners.com

# 在微信开发者工具中临时关闭域名校验进行测试
```

### 企业微信消息无法接收

```bash
# 检查回调 URL 配置
# 确保为 https://tnho-fasteners.com/api/wechat/callback

# 查看企业微信日志
curl https://tnho-fasteners.com/api/wechat/test
```

## 联系方式

如有问题，请联系：
- 技术支持: （填写联系方式）
- GitHub Issues: https://github.com/xiebaole5/PAUL/issues

## 更新日志

### 2025-01-14
- ✅ 域名备案完成
- ✅ 小程序 API 地址切换为域名
- ✅ 企业微信回调 URL 配置为域名
- ✅ 修复对象存储工具导入错误
- ✅ 重启 FastAPI 服务成功
- ⚠️ 需要在 Cloudflare 控制台更新源站 IP
