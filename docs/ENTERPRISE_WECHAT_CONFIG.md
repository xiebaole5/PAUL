# 企业微信智能机器人配置指南

## 前提条件

### 1. 已创建企业微信智能机器人

如果你还没有创建，请参考以下步骤：

1. 登录企业微信管理后台
2. 进入「应用管理」→「应用」→「创建应用」
3. 选择「智能机器人」类型
4. 填写基本信息：
   - 名称：TNHO全能营销助手
   - 简介：一键生成产品宣传视频、图片、文案和语音，支持多种营销场景
   - 头像：上传 TNHO 红色 Logo
   - 可见范围：选择需要使用的部门（销售部、市场部等）

### 2. 获取机器人配置信息

创建完成后，在应用详情页面获取以下信息：

```
CorpId（企业ID）：wwxxxxxxxxxxxxxxxx
AgentId（应用ID）：1000001
Token（随机生成）：tnho_2026_xxxxx
EncodingAESKey（随机生成）：xxxxxxx...
```

## 配置步骤

### 步骤 1：修改 .env 文件

在服务器上的项目目录中，编辑 `.env` 文件：

```bash
cd /root/tnho-fasteners
nano .env
```

添加以下配置：

```env
# 企业微信配置
WECHAT_CORP_ID=wwxxxxxxxxxxxxxxxx
WECHAT_TOKEN=tnho_2026_xxxxx
WECHAT_ENCODING_AES_KEY=xxxxxxxxxxxx

# 火山方舟配置（确保已配置）
ARK_API_KEY=39bf20d0-55b5-4957-baa1-02f4529a3076
ARK_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 对象存储配置（确保已配置）
OSS_ENDPOINT=
OSS_ACCESS_KEY_ID=
OSS_ACCESS_KEY_SECRET=
OSS_BUCKET=
```

**重要提示**：
- 将 `wwxxxxxxxxxxxxxxxx` 替换为你的实际 CorpId
- 将 `tnho_2026_xxxxx` 替换为你的实际 Token
- 将 `xxxxxxxxxxxx` 替换为你的实际 EncodingAESKey

### 步骤 2：配置企业微信回调 URL

在企业微信机器人设置中，配置接收消息服务器：

```
URL：http://47.110.72.148/api/wechat/callback
Token：与 .env 文件中的 WECHAT_TOKEN 一致
EncodingAESKey：与 .env 文件中的 WECHAT_ENCODING_AES_KEY 一致
```

**注意事项**：
- ⚠️ URL 使用 IP 地址，可能需要备案域名
- 如果提示"域名未备案"，先尝试使用 IP 地址
- 如果仍然失败，需要使用备案域名

### 步骤 3：重启 FastAPI 服务

```bash
cd /root/tnho-fasteners

# 停止当前服务
pkill -f "uvicorn.*app.main:app"

# 重新启动服务
nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &

# 查看日志
tail -f app.log
```

### 步骤 4：验证配置

#### 测试接口

```bash
# 测试企业微信接口是否正常
curl http://47.110.72.148/api/wechat/test
```

期望返回：

```json
{
  "status": "ok",
  "message": "企业微信接口正常",
  "corp_id": "wwxxxxxxxxxxxxxxxx",
  "token": "tnho_2026_x...",
  "encoding_aes_key": "xxxxxxx..."
}
```

#### 在企业微信中测试

1. 在企业微信客户端中找到「TNHO全能营销助手」机器人
2. 发送测试消息："你好"
3. 如果机器人正常回复，说明配置成功

## 功能说明

### 支持的功能

#### 1. 视频生成

**指令示例**：
```
生成一个20秒的技术创新视频
```

```
生成25秒品质保证视频，展示产品细节
```

**参数说明**：
- 主题：品质保证、技术创新、工业应用、品牌形象
- 时长：15秒、20秒、25秒、30秒
- 支持图生视频：可上传产品图片

#### 2. 图片生成

**指令示例**：
```
生成一张品质保证主题的宣传海报
```

```
生成产品展示图片，要突出红色TNHO品牌
```

**参数说明**：
- 主题：品质保证、技术创新、工业应用、品牌形象
- 类型：产品图片、宣传海报、场景展示、创意设计、产品手册

#### 3. 脚本生成

**指令示例**：
```
生成20秒技术创新主题的视频脚本
```

```
生成一段产品介绍文案
```

#### 4. 语音合成

**指令示例**：
```
为这段文字生成语音："天虹紧固件，品质保证"
```

```
用男声生成产品解说语音
```

**音色选择**：
- 天净（女声）：温柔亲切
- 云健（男声）：稳重专业
- 小萱（女声）：活泼可爱
- 志强（男声）：有力有磁性
- 小美（女声）：甜美自然

#### 5. 组合功能

**一键生成完整素材包**：
```
帮我生成完整营销素材：
- 20秒技术创新视频
- 产品展示图片
- 营销文案
- 语音解说
```

机器人会依次生成所有内容并返回。

## 常见问题

### Q1: 企业微信提示"URL验证失败"

**原因**：
- .env 文件中的配置与企业微信后台不一致
- 服务未启动或端口错误

**解决**：
```bash
# 检查 .env 配置
cat .env | grep WECHAT

# 检查服务是否运行
ps aux | grep uvicorn

# 检查端口是否正确
netstat -tlnp | grep 9000

# 查看日志
tail -100 app.log
```

### Q2: 发送消息后机器人没有回复

**原因**：
- Agent 未正确初始化
- 模型 API 调用失败
- 对象存储配置错误

**解决**：
```bash
# 查看应用日志
tail -100 app.log | grep "企业微信"

# 检查模型配置
cat .env | grep ARK

# 测试模型 API
curl -X POST https://ark.cn-beijing.volces.com/api/v3/chat/completions \
  -H "Authorization: Bearer $ARK_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"doubao-seed-1-8-251228","messages":[{"role":"user","content":"测试"}]}'
```

### Q3: 生成视频/图片失败

**原因**：
- 模型调用超时
- 文件上传失败
- 对象存储配置错误

**解决**：
```bash
# 检查对象存储配置
cat .env | grep OSS

# 查看详细日志
tail -200 app.log | grep -E "(视频生成|图片生成)"
```

### Q4: 提示"域名未备案"

**原因**：
- 企业微信要求回调 URL 必须是备案域名

**解决方案**：

**方案 A**：临时方案
- 使用 IP 地址：`http://47.110.72.148/api/wechat/callback`
- 在 .env 中配置允许 IP 访问

**方案 B**：正式方案
- 使用备案域名：`https://tnho-fasteners.com/api/wechat/callback`
- 需要完成 ICP 备案

### Q5: 如何切换到备案域名

完成 ICP 备案后：

1. 更新 .env 文件（无需修改，使用相同的配置）
2. 更新企业微信回调 URL：
   ```
   URL：https://tnho-fasteners.com/api/wechat/callback
   ```
3. 重启服务
4. 验证配置

## 日志查看

### 查看应用日志

```bash
# 实时查看日志
tail -f /root/tnho-fasteners/app.log

# 查看企业微信相关日志
tail -f /root/tnho-fasteners/app.log | grep "企业微信"

# 查看错误日志
tail -f /root/tnho-fasteners/app.log | grep -i error
```

### 查看生成进度

```bash
# 查看视频生成日志
tail -f /root/tnho-fasteners/app.log | grep "视频生成"

# 查看图片生成日志
tail -f /root/tnho-fasteners/app.log | grep "图片生成"
```

## 性能优化

### 1. 增加超时时间

如果生成大文件超时，可以调整超时设置：

在 `src/api/enterprise_wechat.py` 中：

```python
response = requests.post(
    f"{BASE_URL}/chat/completions",
    headers=headers,
    json=request_data,
    timeout=600  # 增加到 600 秒
)
```

### 2. 启用缓存

对常用的文案和图片启用缓存，减少重复生成。

### 3. 异步处理

对于耗时的操作（如视频生成），使用异步任务处理。

## 安全建议

1. **保护敏感信息**
   - 不要将 API Key 提交到代码仓库
   - 定期更换 Token 和 EncodingAESKey

2. **限制访问**
   - 配置企业微信机器人的可见范围
   - 仅授权需要的部门使用

3. **监控使用**
   - 定期查看日志
   - 监控 API 调用量和费用

## 下一步

配置完成后，你可以：

1. **测试功能**：在企业微信中测试所有生成功能
2. **培训员工**：向团队成员介绍如何使用机器人
3. **收集反馈**：收集使用反馈，优化 Prompt 和工具
4. **扩展功能**：根据需求添加更多生成能力

---

**文档版本**：1.0.0
**最后更新**：2026-01-14
