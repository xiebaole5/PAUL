# 本地开发环境 - 企业微信验证指南

## 方案说明

不再使用阿里云服务器，直接在**本地电脑**上运行服务，使用**ngrok内网穿透**让企业微信能够访问。

---

## 前置要求

### 1. 本地环境检查
- ✅ Python 3.12.3 已安装
- ✅ FastAPI 已安装
- ✅ Uvicorn 已安装

### 2. 需要安装的工具
- **ngrok**: 内网穿透工具

---

## 安装步骤

### 步骤1：安装ngrok

#### Windows
```bash
# 使用Chocolatey
choco install ngrok

# 或手动下载
# 访问 https://ngrok.com/download
# 下载Windows版本并解压
```

#### macOS
```bash
# 使用Homebrew
brew install ngrok

# 或手动下载
# 访问 https://ngrok.com/download
# 下载macOS版本
```

#### Linux
```bash
# 使用apt (Ubuntu/Debian)
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok

# 或手动下载
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
unzip ngrok-v3-stable-linux-amd64.zip
sudo mv ngrok /usr/local/bin
```

### 步骤2：注册ngrok账号
1. 访问 https://ngrok.com/
2. 注册免费账号
3. 获取authtoken
4. 配置authtoken：
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

---

## 使用步骤

### 步骤1：启动本地FastAPI服务

在本地电脑的终端中：

```bash
cd /path/to/your/project
# 确保在项目目录，有app.py和src/文件夹

# 启动服务（本地使用8000端口，避免冲突）
python3 -m uvicorn app:app --host 0.0.0.0 --port 8000
```

验证服务是否启动：
```bash
curl http://localhost:8000/api/wechat/test
```

应该返回：
```json
{"status":"ok","message":"企业微信接口正常","token_configured":true}
```

### 步骤2：创建ngrok隧道

在**另一个终端**中运行：

```bash
ngrok http 8000
```

你会看到类似输出：
```
Forwarding  https://xxxx-xx-xx-xx-xx.ngrok-free.app -> http://localhost:8000
Forwarding  https://xxxx-xx-xx-xx-xx.ngrok-free.app -> http://localhost:8000
```

**记住这个URL**，例如：`https://xxxx-xx-xx-xx-xx.ngrok-free.app`

### 步骤3：配置企业微信回调URL

在企业微信管理后台：

1. 打开应用管理
2. 找到"TNHO全能营销助手"
3. 进入开发者配置
4. 填写以下信息：

```
回调URL: https://xxxx-xx-xx-xx-xx.ngrok-free.app/api/wechat/callback
Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
```

**注意**：
- 使用ngrok提供的HTTPS URL
- 路径是 `/api/wechat/callback`
- 不要使用HTTP，企业微信要求HTTPS

### 步骤4：测试验证

1. 在企业微信后台点击"验证"按钮
2. 观察本地FastAPI服务的日志输出
3. 应该看到类似日志：

```
INFO:src.api.middleware:收到请求
INFO:src.api.middleware:  客户端 IP: [企业微信IP]
INFO:src.api.middleware:  URL: https://xxxx.ngrok-free.app/api/wechat/callback
INFO:src.api.wechat_callback_simple:收到企业微信 URL 验证请求
INFO:src.api.wechat_callback_simple:✅ 签名验证通过
```

---

## 故障排查

### 问题1：ngrok命令未找到
**解决**：
- 确认ngrok已正确安装
- 将ngrok路径添加到PATH环境变量
- 或使用完整路径运行

### 问题2：ngrok启动失败
**解决**：
```bash
# 检查是否配置了authtoken
ngrok config check

# 重新配置authtoken
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### 问题3：企业微信验证失败
**解决**：
1. 确认使用的是HTTPS URL（不是HTTP）
2. 检查Token是否正确
3. 查看本地服务日志
4. 使用ngrok的Web界面查看请求（http://localhost:4040）

### 问题4：本地服务无法启动
**解决**：
```bash
# 检查端口是否被占用
lsof -i :8000  # macOS/Linux
netstat -ano | findstr :8000  # Windows

# 更换端口
python3 -m uvicorn app:app --host 0.0.0.0 --port 8888
ngrok http 8888
```

---

## ngrok监控

### 查看请求日志
ngrok提供了一个Web界面来监控所有请求：

```
打开浏览器访问: http://localhost:4040
```

你可以在这里看到：
- 所有传入的HTTP请求
- 请求头、响应头
- 请求体、响应体
- 请求时间

这对调试非常有用！

---

## 常用命令

### ngrok
```bash
# 启动HTTP隧道
ngrok http 8000

# 指定子域名（需要付费）
ngrok http 8000 --domain=myapp.ngrok-free.app

# 查看配置
ngrok config check

# 查看版本
ngrok version
```

### FastAPI
```bash
# 启动服务
python3 -m uvicorn app:app --host 0.0.0.0 --port 8000

# 开发模式（自动重载）
python3 -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload

# 指定工作目录
python3 -m uvicorn app:app --host 0.0.0.0 --port 8000 --workers 4
```

---

## 优势

使用本地开发 + ngrok的优势：

1. **快速开发**：无需每次修改都部署到服务器
2. **实时调试**：直接在本地查看日志和调试
3. **免费使用**：ngrok免费版足够开发使用
4. **HTTPS支持**：ngrok自动提供HTTPS
5. **易于分享**：快速分享给同事测试

---

## 注意事项

### ngrok免费版限制
- URL会随机变化（每次重启ngrok）
- 有并发连接限制
- 有带宽限制

**解决方案**：
- 企业微信配置一次验证完成后，可以将服务部署到服务器
- 或使用付费版获得固定域名

### 安全
- ngrok URL是公开的，任何人都可以访问
- 生产环境请使用正式域名和服务器

---

## 下一步

1. ✅ 安装ngrok
2. ✅ 配置ngrok authtoken
3. ✅ 启动本地FastAPI服务
4. ✅ 创建ngrok隧道
5. ✅ 配置企业微信回调URL
6. ✅ 验证成功

---

**创建时间**: 2026-01-15 02:42
**适用于**: 本地开发环境
**工具**: ngrok + FastAPI
