# 服务器更新命令

请按顺序在服务器上执行以下命令：

## 1. 切换到项目目录

```bash
cd /workspace/projects
```

## 2. 拉取最新代码

```bash
git fetch origin main
git reset --hard origin/main
```

## 3. 清理 Python 缓存

```bash
find src/ -name "*.pyc" -delete
find src/ -name "__pycache__" -type d -exec rm -rf {} +
```

## 4. 停止所有旧服务

```bash
pkill -9 -f "python3.*app"
pkill -9 -f "uvicorn"
pkill -9 -f "python.*app.main"
sleep 3
```

## 5. 验证旧服务已停止

```bash
ps aux | grep python | grep -E "(uvicorn|app)" | grep -v grep
```

应该没有输出（所有服务已停止）

## 6. 启动新的 FastAPI 服务

```bash
nohup python3 app.py > /tmp/fastapi.log 2>&1 &
```

## 7. 查看服务启动日志

```bash
sleep 3
tail -50 /tmp/fastapi.log
```

## 8. 验证服务状态

```bash
# 检查进程
ps aux | grep 'python3 app.py' | grep -v grep

# 健康检查
curl -s http://localhost:8080/health

# 测试企业微信接口
curl -s http://localhost:8080/api/wechat/test
```

## 9. 测试企业微信 URL 验证

```bash
# 生成测试参数
python3 << 'EOF'
import hashlib
import time
import random
import string

TOKEN = "gkIzrwgJI041s52TPAszz2j5iGnpZ4"
timestamp = str(int(time.time()))
nonce = ''.join(random.choices(string.ascii_letters + string.digits, k=10))
echostr = ''.join(random.choices(string.ascii_letters + string.digits, k=16))

arr = [TOKEN, timestamp, nonce, echostr]
arr.sort()
s = ''.join(arr)
sha1 = hashlib.sha1()
sha1.update(s.encode('utf-8'))
signature = sha1.hexdigest()

print(f"curl -s \"http://localhost:8080/api/wechat/callback?msg_signature={signature}&timestamp={timestamp}&nonce={nonce}&echostr={echostr}\"")
EOF
```

复制输出的命令并执行。

## 10. 持续监控日志（可选）

```bash
tail -f /tmp/fastapi.log
```

按 Ctrl+C 停止监控

## 验证成功的标志

1. `curl -s http://localhost:8080/api/wechat/test` 返回：
   ```json
   {"status":"ok","message":"企业微信接口正常","token_configured":true}
   ```

2. URL 验证测试返回 echostr 的值（明文）

3. 日志中显示：
   ```
   INFO:src.api.wechat_callback_simple:企业微信接口 - Token: gkIzrwgJI0...
   ```

**不是**：
   ```
   INFO:src.api.enterprise_wechat:收到企业微信验证请求...
   ```

## 如果遇到问题

### 端口被占用

```bash
# 查找占用 8080 端口的进程
lsof -i :8080

# 停止该进程
kill -9 <PID>
```

### 查看详细日志

```bash
cat /tmp/fastapi.log
```

### 重启服务

```bash
pkill -9 -f 'python3 app.py'
sleep 2
cd /workspace/projects
nohup python3 app.py > /tmp/fastapi.log 2>&1 &
```
