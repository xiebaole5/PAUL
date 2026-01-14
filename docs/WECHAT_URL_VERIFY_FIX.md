# 企业微信 URL 验证修复指南

## 问题诊断

企业微信 URL 验证失败的根本原因：**`echostr` 不需要解密！**

### 企业微信官方文档说明

- **URL 验证阶段（GET 请求）**：
  - 企业微信发送参数：`msg_signature`, `timestamp`, `nonce`, `echostr`
  - **`echostr` 是明文随机字符串，不需要解密**
  - 只需验证签名后直接返回 `echostr` 即可

- **消息推送阶段（POST 请求）**：
  - 只有 `encrypted_msg` 字段才需要解密

### 当前代码的问题

之前的代码试图对 `echostr` 进行 AES 解密，这是错误的，导致：
- 解密后的 Corp ID 为空字符串
- 验证失败：`Corp ID 不匹配`

## 修复步骤

### 1. 在服务器上运行修复脚本

```bash
cd /root/PAUL
bash scripts/fix_wechat_url_verify.sh
```

这个脚本会：
- ✅ 停止所有 Python 服务
- ✅ 清理 Python 缓存
- ✅ 检查代码是否正确
- ✅ 启动 FastAPI 服务
- ✅ 验证服务状态

### 2. 如果脚本执行失败，手动修复

#### 步骤 1：停止服务
```bash
pkill -9 -f "python.*app"
pkill -9 -f "uvicorn"
sleep 2
```

#### 步骤 2：清理缓存
```bash
cd /root/PAUL
find src/ -name "*.pyc" -delete
find src/ -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
```

#### 步骤 3：确认代码正确
```bash
# 检查 wechat_callback_simple.py 是否包含正确的返回逻辑
grep "直接返回 echostr" src/api/wechat_callback_simple.py

# 应该输出：
#         # 4. 直接返回 echostr（明文，不需要解密）
#         return echostr
```

#### 步骤 4：检查路由冲突
```bash
# 确认没有其他文件导入 enterprise_wechat.py
grep -r "from.*enterprise_wechat\|import.*enterprise_wechat" src/ --include="*.py" | grep -v ".pyc"
# 应该没有输出（除了 enterprise_wechat.py 自身）
```

#### 步骤 5：启动服务
```bash
cd /root/PAUL
nohup venv/bin/python app.py > /tmp/fastapi.log 2>&1 &
```

#### 步骤 6：验证服务
```bash
# 等待 5 秒
sleep 5

# 测试健康检查
curl http://localhost:8080/health

# 测试企业微信接口
curl http://localhost:8080/api/wechat/test
```

### 3. 在企业微信后台配置

配置信息：
- **回调 URL**: `http://47.110.72.148:8080/api/wechat/callback`
- **Token**: `gkIzrwgJI041s52TPAszz2j5iGnpZ4`
- **EncodingAESKey**: `2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr`
- **Corp ID**: `ww4564cfcc6de70e6c`

### 4. 验证成功后

验证成功后，企业微信会发送 POST 请求进行消息推送。此时需要在 `wechat_callback_simple.py` 中的 `wechat_callback_post` 函数实现消息解密和处理逻辑。

## 常见问题

### 问题 1：服务启动失败

**症状**：`curl http://localhost:8080/health` 返回连接错误

**解决**：
```bash
# 查看启动日志
cat /tmp/fastapi.log

# 检查端口占用
netstat -tulpn | grep 8080
```

### 问题 2：验证仍然失败

**症状**：企业微信后台提示 "echostr校验失败"

**解决**：
```bash
# 查看请求日志
tail -f /tmp/fastapi.log

# 在企业微信后台点击"验证"按钮，观察日志输出
# 确认：
# 1. 签名验证通过
# 2. 直接返回了 echostr（明文）
```

### 问题 3：端口冲突

**症状**：启动服务时报错 "address already in use"

**解决**：
```bash
# 查找占用端口的进程
lsof -i :8080

# 杀死进程
kill -9 <PID>

# 重新启动
```

## 正确的实现逻辑

```python
@router.get("/callback")
async def wechat_url_verify(
    msg_signature: str,
    timestamp: str,
    nonce: str,
    echostr: str
):
    """
    企业微信 URL 验证（GET 请求）
    """
    # 1. 验证签名
    arr = [WECHAT_TOKEN, timestamp, nonce, echostr]
    arr.sort()
    signature = hashlib.sha1(''.join(arr).encode()).hexdigest()

    if signature != msg_signature:
        raise HTTPException(status_code=400, detail="签名验证失败")

    # 2. 直接返回 echostr（明文，不需要解密）
    return echostr
```

## 关键要点

- ✅ **echostr 是明文**：不要解密
- ✅ **只验证签名**：SHA1 验证通过即可
- ✅ **直接返回**：`return echostr`
- ❌ **不需要 AES 解密**：在 URL 验证阶段
- ❌ **不需要验证 Corp ID**：在 URL 验证阶段

## 联系支持

如果按照上述步骤操作后仍有问题，请提供以下信息：
1. `/tmp/fastapi.log` 日志内容
2. 企业微信后台的错误信息
3. `curl http://localhost:8080/api/wechat/test` 的输出
