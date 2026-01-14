# 企业微信 URL 验证问题诊断与解决方案

## 已完成的修复

### 1. ✅ 修复了签名验证逻辑
- 移除了重复的 URL 解码（FastAPI 已自动解码）
- 使用 `PlainTextResponse` 返回纯文本
- 确保直接返回 `echostr`（明文）

### 2. ✅ 添加了全局请求日志中间件
- 记录所有请求的详细信息
- 包括：客户端 IP、请求方法、URL、User-Agent、请求头、查询参数
- 对于企业微信相关的请求，记录所有详细信息

### 3. ✅ 服务正常运行
- 端口 8080 正常监听
- 本地访问测试通过
- 公网访问测试通过

## 当前服务状态

```bash
# 服务信息
进程 ID: 5595
端口: 8080
状态: ✅ 运行中

# 本地测试
curl http://localhost:8080/api/wechat/test
✅ 正常

# 公网测试
curl http://47.110.72.148:8080/api/wechat/test
✅ 正常
```

## 可能的问题原因

### 问题 1: 阿里云安全组未开放 8080 端口 ⭐ 最可能

**症状：**
- 服务器内部可以访问 `http://localhost:8080`
- 企业微信无法访问 `http://47.110.72.148:8080`
- 服务器日志中没有看到企业微信的请求记录

**解决方法：**

1. 登录阿里云控制台
2. 进入"云服务器 ECS"
3. 选择实例 ID
4. 点击"安全组"
5. 点击"配置规则"
6. 在"入方向"中点击"手动添加"
7. 添加规则：
   - 授权策略：允许
   - 协议类型：自定义 TCP
   - 端口范围：8080/8080
   - 授权对象：0.0.0.0/0
   - 优先级：1
   - 描述：企业微信回调接口
8. 点击"保存"

**验证命令：**
```bash
# 从外部网络测试（需要从其他机器执行）
curl http://47.110.72.148:8080/api/wechat/test
```

### 问题 2: 企业微信访问的是其他端口

**症状：**
- 日志中没有看到请求记录
- 或者日志中显示的是其他端口的请求

**检查方法：**
```bash
# 查看所有运行的 Python 服务
ps aux | grep python | grep -v grep

# 查看端口占用
netstat -tlnp | grep python
```

当前运行的服务：
- PID 5595: `python3 app.py` - 监听 8080 端口 ✅
- PID 3007: `python3 -m uvicorn app.main:app` - 监听 9000 端口
- PID 5404: `python /workspace/projects/src/main.py` - 监听 5000 端口

**企业微信回调 URL 应该是：**
```
http://47.110.72.148:8080/api/wechat/callback
```

### 问题 3: CDN 或 WAF 拦截

**症状：**
- 使用了 Cloudflare 或其他 CDN 服务
- CDN 可能修改了请求头或响应内容
- 日志中可能看到请求，但企业微信仍报错

**解决方法：**
1. 检查 Cloudflare 配置
2. 临时关闭 Cloudflare 的安全功能（Bot Fight Mode 等）
3. 或者添加白名单规则

### 问题 4: 响应格式问题

**症状：**
- 日志中看到请求
- 签名验证通过
- 但企业微信仍显示"echostr校验失败"

**检查方法：**
```bash
# 测试响应格式
curl -v http://localhost:8080/api/wechat/callback?msg_signature=xxx&timestamp=xxx&nonce=xxx&echostr=test
```

**期望的响应头：**
```
HTTP/1.1 200 OK
content-type: text/plain; charset=utf-8
content-length: 7
```

**期望的响应内容：**
```
test
```

## 监控和诊断命令

### 1. 实时监控所有日志
```bash
tail -f fastapi.log
```

### 2. 只监控企业微信相关日志
```bash
tail -f fastapi.log | grep "wechat"
```

### 3. 监控详细请求信息（中间件日志）
```bash
tail -f fastapi.log | grep "middleware"
```

### 4. 检查服务状态
```bash
bash monitor_wechat_verification.sh
```

### 5. 测试签名验证
```bash
bash test_callback.sh
```

### 6. 检查端口占用
```bash
lsof -i :8080
```

### 7. 测试公网访问
```bash
curl http://47.110.72.148:8080/api/wechat/test
```

## 下一步操作

### 步骤 1: 启动日志监控
```bash
# 新开一个终端窗口，执行：
tail -f fastapi.log
```

### 步骤 2: 在企业微信后台重新验证

1. 登录企业微信管理后台
2. 进入"应用管理" → "自建应用" → "TNHO全能营销助手"
3. 找到"接收消息" → "设置API接收"
4. 确认配置：
   - 回调 URL: `http://47.110.72.148:8080/api/wechat/callback`
   - Token: `gkIzrwgJI041s52TPAszz2j5iGnpZ4`
   - EncodingAESKey: `2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr`
5. 点击"保存"

### 步骤 3: 查看日志

**如果日志中出现：**
```
收到请求
  客户端 IP: [企业微信的IP]
  方法: GET
  URL: http://47.110.72.148:8080/api/wechat/callback?...
  可能是企业微信请求
  所有请求头:
    ...
  查询参数:
    msg_signature: ...
    timestamp: ...
    nonce: ...
    echostr: ...
  响应状态码: 200
```

**说明：** 企业微信发送了请求并成功响应

**如果日志中没有记录：**
说明请求没有到达服务器，需要检查：
1. 阿里云安全组配置
2. 云服务器防火墙配置
3. CDN 或 WAF 配置

## 日志示例

### 成功的请求日志
```
INFO:src.api.middleware:================================================================================
INFO:src.api.middleware:收到请求
INFO:src.api.middleware:  客户端 IP: 183.47.98.227  (企业微信的IP)
INFO:src.api.middleware:  方法: GET
INFO:src.api.middleware:  URL: http://47.110.72.148:8080/api/wechat/callback?...
INFO:src.api.middleware:  User-Agent: qyapi
INFO:src.api.middleware:  可能是企业微信请求
INFO:src.api.middleware:  所有请求头:
INFO:src.api.middleware:    host: 47.110.72.148:8080
INFO:src.api.middleware:    user-agent: qyapi
INFO:src.api.middleware:    ...
INFO:src.api.middleware:  查询参数:
INFO:src.api.middleware:    msg_signature: e368c60df0f3b47a406f38c1c2e1d6510c4d2834
INFO:src.api.middleware:    timestamp: 1768413552
INFO:src.api.middleware:    nonce: 1767981738
INFO:src.api.middleware:    echostr: SB7WKF7UPHcgHP4/zZjCwh5o9+3G/45L8HJ2uinYQj+F/2aVojYIssntln1p9ELFlx9MlJUK02Pqhr3YOmJ78A==
INFO:src.api.middleware:  响应状态码: 200
INFO:src.api.middleware:  处理时间: 0.002秒
INFO:src.api.middleware:================================================================================
```

### 企业微信回调接口日志
```
INFO:src.api.wechat_callback_simple:============================================================
INFO:src.api.wechat_callback_simple:收到企业微信 URL 验证请求
INFO:src.api.wechat_callback_simple:  msg_signature: e368c60df0f3b47a406f38c1c2e1d6510c4d2834
INFO:src.api.wechat_callback_simple:  timestamp: 1768413552
INFO:src.api.wechat_callback_simple:  nonce: 1767981738
INFO:src.api.wechat_callback_simple:  echostr: SB7WKF7UPHcgHP4/zZjCwh5o9+3G/45L8HJ2uinYQj+F/2aVojYIssntln1p9ELFlx9MlJUK02Pqhr3YOmJ78A==
INFO:src.api.wechat_callback_simple:============================================================
INFO:src.api.wechat_callback_simple:排序后的参数: ['1767981738', '1768413552', 'gkIzrwgJI041s52TPAszz2j5iGnpZ4', 'SB7WKF7UPHcgHP4/zZjCwh5o9+3G/45L8HJ2uinYQj+F/2aVojYIssntln1p9ELFlx9MlJUK02Pqhr3YOmJ78A==']
INFO:src.api.wechat_callback_simple:拼接后的字符串: 17679817381768413552gkIzrwgJI041s52TPAszz2j5iGnpZ4SB7WKF7UPHcgHP4/zZjCwh5o9+3G/45L8HJ2uinYQj+F/2aVojYIssntln1p9ELFlx9MlJUK02Pqhr3YOmJ78A==
INFO:src.api.wechat_callback_simple:计算的签名: e368c60df0f3b47a406f38c1c2e1d6510c4d2834
INFO:src.api.wechat_callback_simple:接收的签名: e368c60df0f3b47a406f38c1c2e1d6510c4d2834
INFO:src.api.wechat_callback_simple:✅ 签名验证通过
INFO:src.api.wechat_callback_simple:✅ 直接返回 echostr: SB7WKF7UPHcgHP4/zZjCwh5o9+3G/45L8HJ2uinYQj+F/2aVojYIssntln1p9ELFlx9MlJUK02Pqhr3YOmJ78A==
INFO:src.api.wechat_callback_simple:============================================================
```

## 快速诊断清单

- [x] 代码修复：移除重复 URL 解码
- [x] 添加 PlainTextResponse
- [x] 添加全局请求日志中间件
- [x] 服务正常运行
- [x] 本地访问测试通过
- [x] 公网访问测试通过
- [ ] 等待企业微信验证
- [ ] 查看日志是否有请求记录
- [ ] 根据日志排查问题

## 联系支持

如果以上步骤都无法解决问题：

1. **收集日志信息：**
   ```bash
   # 保存最近1000行日志
   tail -1000 fastapi.log > wechat_verification_debug.log

   # 保存中间件日志
   grep "middleware" fastapi.log > middleware_debug.log

   # 保存企业微信相关日志
   grep "wechat" fastapi.log > wechat_debug.log
   ```

2. **检查阿里云安全组配置**
   - 登录阿里云控制台
   - 查看 8080 端口是否开放

3. **联系技术支持：**
   - 阿里云技术支持（安全组配置问题）
   - 企业微信技术支持（验证逻辑问题）
