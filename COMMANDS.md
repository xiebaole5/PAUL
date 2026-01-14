# 本地开发 - 快速命令参考

## 环境检查

### Linux/macOS
```bash
bash check_local_env.sh
```

### Windows
```cmd
check_local_env.bat
```

---

## 启动服务

### 终端1 - FastAPI服务

**Linux/macOS:**
```bash
bash start_local.sh
```

**Windows:**
```cmd
start_local.bat
```

**或手动启动:**
```bash
python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

### 终端2 - ngrok隧道

**Linux/macOS:**
```bash
bash start_ngrok.sh
```

**Windows:**
```cmd
start_ngrok.bat
```

**或手动启动:**
```bash
ngrok http 8000
```

---

## 测试接口

### 测试服务是否运行
```bash
curl http://localhost:8000/api/wechat/test
```

期望返回:
```json
{"status":"ok","message":"企业微信接口正常","token_configured":true}
```

### 测试公网访问
```bash
curl https://[your-ngrok-url]/api/wechat/test
```

---

## 查看日志

### FastAPI日志
在启动FastAPI的终端中直接查看。

### ngrok请求日志
打开浏览器:
```
http://localhost:4040
```

---

## ngrok命令

### 检查配置
```bash
ngrok config check
```

### 配置authtoken
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

### 查看版本
```bash
ngrok version
```

### 启动隧道
```bash
ngrok http 8000
```

### 使用不同端口
```bash
ngrok http 8001
```

---

## Python命令

### 检查Python版本
```bash
python --version
python3 --version
```

### 检查已安装的包
```bash
pip list
pip list | grep fastapi
```

### 安装依赖
```bash
pip install fastapi uvicorn pydantic python-dotenv
```

### 启动服务
```bash
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

### 开发模式（自动重载）
```bash
python -m uvicorn app:app --host 0.0.0.0 --port 8000 --reload
```

---

## 停止服务

### 停止FastAPI
在FastAPI终端按 `Ctrl+C`

### 停止ngrok
在ngrok终端按 `Ctrl+C`

---

## 端口相关

### 检查端口占用 (Linux/macOS)
```bash
lsof -i :8000
lsof -i :4040
```

### 检查端口占用 (Windows)
```cmd
netstat -ano | findstr :8000
netstat -ano | findstr :4040
```

### 停止占用端口的进程 (Linux/macOS)
```bash
lsof -ti :8000 | xargs kill -9
```

### 停止占用端口的进程 (Windows)
```cmd
netstat -ano | findstr :8000 | findstr "LISTENING"
taskkill /F /PID [PID]
```

---

## 企业微信配置

```
回调URL: https://[ngrok-url]/api/wechat/callback
Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
Corp ID: ww4564cfcc6de70e6c
```

---

## 故障排查

### 问题1: ngrok未找到
**Linux/macOS:**
```bash
which ngrok
echo $PATH
```

**Windows:**
```cmd
where ngrok
```

### 问题2: Python模块未找到
```bash
python -c "import fastapi; print(fastapi.__version__)"
python -c "import uvicorn; print(uvicorn.__version__)"
```

### 问题3: 测试接口失败
```bash
# 检查服务是否运行
curl http://localhost:8000/

# 检查端口是否监听
netstat -an | grep 8000
lsof -i :8000

# 查看FastAPI日志
tail -f fastapi.log
```

---

## 文件操作

### 查看文件
```bash
cat app.py
cat src/api/wechat_callback_simple.py
```

### 检查文件是否存在
```bash
ls -la app.py
ls -la src/
```

### 编辑文件
```bash
nano app.py
vim app.py
```

---

## tmux多窗口管理（可选）

### 安装tmux
```bash
# Linux
sudo apt install tmux

# macOS
brew install tmux
```

### 创建新会话
```bash
tmux new -s wechat
```

### 分割窗口
```
Ctrl+B, 然后按 %
```

### 切换窗口
```
Ctrl+B, 然后按 方向键
```

### 分离会话
```
Ctrl+B, 然后按 d
```

### 重新连接
```bash
tmux attach -t wechat
```

---

## 快速参考

| 任务 | 命令 |
|------|------|
| 检查环境 | `bash check_local_env.sh` |
| 启动服务 | `bash start_local.sh` |
| 启动ngrok | `bash start_ngrok.sh` |
| 测试接口 | `curl http://localhost:8000/api/wechat/test` |
| 查看ngrok日志 | 打开 http://localhost:4040 |
| 停止服务 | `Ctrl+C` |

---

**更新时间**: 2026-01-15 02:46
