# 本地开发快速启动指南

## 前提条件

1. ✅ 已安装 Python 3.12+
2. ✅ 已安装 FastAPI、Uvicorn 等依赖
3. ✅ 已安装 ngrok

如果以上条件未满足，请先运行环境检查：
- **Linux/macOS**: `bash check_local_env.sh`
- **Windows**: `check_local_env.bat`

---

## 快速启动（3步）

### 第1步：启动本地服务

打开第一个终端：

**Linux/macOS:**
```bash
bash start_local.sh
```

**Windows:**
```cmd
start_local.bat
```

服务启动后，你应该看到：
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

测试服务是否正常（在新的终端）：
```bash
curl http://localhost:8000/api/wechat/test
```

应该返回：
```json
{"status":"ok","message":"企业微信接口正常","token_configured":true}
```

### 第2步：启动ngrok隧道

打开第二个终端：

**Linux/macOS:**
```bash
bash start_ngrok.sh
```

**Windows:**
```cmd
start_ngrok.bat
```

ngrok启动后，你会看到：
```
Forwarding  https://xxxx-xx-xx-xx-xx.ngrok-free.app -> http://localhost:8000
```

**复制这个HTTPS URL**，例如：`https://abcd-1234-5678.ngrok-free.app`

### 第3步：配置企业微信

在企业微信管理后台：

1. 打开应用管理
2. 找到"TNHO全能营销助手"
3. 进入开发者配置
4. 填写：

```
回调URL: https://abcd-1234-5678.ngrok-free.app/api/wechat/callback
Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
```

5. 点击"验证"按钮

### 验证成功

回到第一个终端（FastAPI服务），你应该看到：
```
INFO:src.api.wechat_callback_simple:收到企业微信 URL 验证请求
INFO:src.api.wechat_callback_simple:✅ 签名验证通过
```

同时，企业微信后台会显示"URL验证成功"。

---

## 监控请求

### 方法1：查看FastAPI日志
在FastAPI服务的终端中，实时查看所有请求日志。

### 方法2：使用ngrok Web界面
打开浏览器访问：
```
http://localhost:4040
```

你可以看到：
- 所有传入的HTTP请求
- 请求头、响应头
- 请求体、响应体

---

## 端口说明

| 端口 | 用途 | 说明 |
|------|------|------|
| 8000 | FastAPI服务 | 本地API服务端口 |
| 4040 | ngrok面板 | 查看ngrok请求详情 |

如果端口被占用，脚本会自动使用8001端口。

---

## 停止服务

### 停止ngrok
在ngrok终端中按 `Ctrl+C`

### 停止FastAPI服务
在FastAPI服务终端中按 `Ctrl+C`

---

## 常见问题

### Q1: ngrok URL每次都变怎么办？
A: ngrok免费版的URL是随机的。如果需要固定域名，可以：
- 使用ngrok付费版
- 验证成功后将服务部署到正式服务器

### Q2: 企业微信验证失败怎么办？
A:
1. 确认使用的是HTTPS URL（不是HTTP）
2. 检查Token是否正确
3. 查看ngrok面板（http://localhost:4040）看请求是否到达
4. 查看FastAPI服务的日志

### Q3: 两个终端窗口太麻烦？
A: 可以使用tmux或screen在一个窗口中运行多个服务。

**使用tmux:**
```bash
# 安装tmux
sudo apt install tmux  # Linux
brew install tmux      # macOS

# 创建新会话
tmux new -s wechat

# 分割窗口
Ctrl+B, 然后按 %

# 切换窗口
Ctrl+B, 然后按 方向键
```

### Q4: 本地开发完成后如何部署？
A:
1. 将代码上传到服务器
2. 在服务器上安装依赖
3. 启动FastAPI服务
4. 配置Nginx反向代理
5. 配置SSL证书
6. 更新企业微信回调URL为正式域名

---

## 文件说明

| 文件 | 说明 |
|------|------|
| `app.py` | FastAPI应用入口 |
| `src/api/wechat_callback_simple.py` | 企业微信验证接口 |
| `src/api/middleware.py` | 请求日志中间件 |
| `.env` | 环境变量配置 |
| `check_local_env.sh/bat` | 环境检查脚本 |
| `start_local.sh/bat` | 启动FastAPI服务 |
| `start_ngrok.sh/bat` | 启动ngrok隧道 |

---

## 参考文档

- [本地开发环境完整指南](./LOCAL_SETUP_GUIDE.md)
- [企业微信架构说明](./ENTERPRISE_WECHAT_EXPLAINED.md)
- [ngrok官方文档](https://ngrok.com/docs)

---

**快速检查清单:**

- [ ] Python 3.12+ 已安装
- [ ] FastAPI依赖已安装
- [ ] ngrok已安装并配置
- [ ] 本地FastAPI服务已启动
- [ ] ngrok隧道已创建
- [ ] 企业微信回调URL已配置
- [ ] 验证成功

**开始时间**: _
**验证完成时间**: _
