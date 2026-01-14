# 企业微信 URL 验证失败 - 诊断建议

## 当前状态

✅ **本地测试通过**
- 服务正常运行在 8080 端口
- 签名验证逻辑正确
- 返回格式正确（`text/plain`，返回 `echostr` 明文）

❌ **企业微信验证失败**
- 企业微信后台显示"echostr校验失败"
- 服务器日志中没有看到企业微信的请求记录

## 可能的原因

### 1. 阿里云安全组未开放 8080 端口 ⭐ 最可能

**症状：**
- 服务器内部可以访问 `http://localhost:8080`
- 外部无法访问 `http://47.110.72.148:8080`

**解决方法：**

1. 登录阿里云控制台
2. 进入"云服务器 ECS" → "实例" → 找到这台服务器
3. 点击"安全组" → "配置规则"
4. 在"入方向"中添加规则：
   - 授权策略：允许
   - 协议类型：自定义 TCP
   - 端口范围：8080/8080
   - 授权对象：0.0.0.0/0
   - 优先级：1
5. 保存规则

**验证命令：**
```bash
# 从服务器内部测试公网 IP 访问
curl http://47.110.72.148:8080/api/wechat/test
```

### 2. 云服务器防火墙未开放 8080 端口

**症状：**
- `iptables` 或 `firewalld` 阻止了外部访问

**解决方法：**

```bash
# 检查防火墙状态
sudo iptables -L -n

# 如果有防火墙规则，添加允许 8080 端口
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT

# 保存规则（如果需要）
sudo iptables-save > /etc/iptables/rules.v4
```

### 3. 企业微信访问的是其他服务

**症状：**
- 有多个服务运行在不同端口
- 企业微信可能访问了错误的端口

**检查方法：**

```bash
# 检查所有运行的 Python 服务
ps aux | grep python | grep -v grep

# 检查端口占用
netstat -tlnp | grep python
```

当前发现的服务：
- PID 5368: `python3 app.py` - 监听 8080 端口 ✅
- PID 3007: `python3 -m uvicorn app.main:app` - 监听 9000 端口
- PID 5404: `python /workspace/projects/src/main.py` - 监听 5000 端口

### 4. Nginx 反向代理配置问题

**症状：**
- 有 Nginx 在运行
- Nginx 可能修改了响应内容或重定向了请求

**检查方法：**

```bash
# 检查 Nginx 是否运行
ps aux | grep nginx | grep -v grep

# 检查 Nginx 配置
cat /etc/nginx/sites-enabled/default
```

### 5. CDN 或 WAF 拦截请求

**症状：**
- 使用了 Cloudflare 等服务
- WAF 可能拦截了请求或修改了响应

**解决方法：**
- 临时关闭 Cloudflare 的安全功能
- 或者在 Cloudflare 中添加白名单规则

## 诊断步骤

### 步骤 1: 测试公网 IP 是否可访问

```bash
# 从服务器内部测试公网 IP
curl -v http://47.110.72.148:8080/api/wechat/test
```

**期望结果：** 返回 JSON 格式的响应
```json
{"status":"ok","message":"企业微信接口正常","token_configured":true}
```

**如果失败：** 说明端口未对外开放，检查阿里云安全组

### 步骤 2: 监控日志并让企业微信验证

```bash
# 实时监控日志
tail -f fastapi.log

# 或者只监控企业微信相关的日志
tail -f fastapi.log | grep "wechat_callback_simple"
```

然后在企业微信后台重新进行 URL 验证。

**期望结果：** 日志中出现"收到企业微信 URL 验证请求"

**如果日志中没有记录：** 说明请求没有到达服务器，检查防火墙或安全组

### 步骤 3: 测试签名验证逻辑

```bash
# 运行测试脚本
bash test_callback.sh
```

**期望结果：** 返回 `test123`

### 步骤 4: 检查响应格式

```bash
# 运行响应格式测试
bash test_response_format.sh
```

**期望结果：**
- HTTP 状态码：200
- Content-Type: `text/plain; charset=utf-8`
- 响应内容：`test123`（纯文本）

## 推荐操作顺序

1. **首先检查阿里云安全组**（最可能的问题）
   - 登录阿里云控制台
   - 添加 8080 端口入站规则
   - 保存后测试公网访问

2. **然后监控日志并重新验证**
   ```bash
   tail -f fastapi.log
   ```
   - 在企业微信后台重新验证
   - 查看日志中是否有请求记录

3. **如果还是没有请求记录**
   - 检查服务器防火墙
   - 检查是否有其他服务占用端口
   - 检查是否有 CDN 或 WAF 拦截

4. **如果有请求记录但验证失败**
   - 查看日志中的签名计算过程
   - 对比企业微信发送的签名和计算的签名
   - 检查 echostr 是否正确

## 当前服务状态

- 服务运行正常：✅
- 端口监听：✅ (0.0.0.0:8080)
- 签名验证逻辑：✅
- 响应格式：✅ (text/plain)
- 公网访问：❓ (需验证)

## 快速检查命令

```bash
# 检查端口监听
lsof -i :8080

# 检查服务状态
ps aux | grep "python app.py" | grep -v grep

# 测试本地访问
curl http://localhost:8080/api/wechat/test

# 测试公网访问
curl http://47.110.72.148:8080/api/wechat/test

# 监控日志
tail -f fastapi.log
```

## 联系支持

如果以上步骤都无法解决问题，请联系：
- 阿里云技术支持（检查安全组配置）
- 企业微信技术支持（确认验证逻辑）
