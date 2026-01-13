# 小程序 Mixed Content 错误修复指南

## 问题描述

在微信开发者工具中测试小程序时，出现以下错误：

```
Mixed Content: The page at 'https://servicewechat.com/...' was loaded over HTTPS,
but requested an insecure image 'http://47.110.72.148/assets/uploads/...'.
This request has been blocked; content must be served over HTTPS.
```

### 问题原因

- 小程序页面通过 **HTTPS** 协议加载（微信安全要求）
- 但图片上传接口返回的 URL 使用 **HTTP** 协议的 IP 地址：`http://47.110.72.148/...`
- 浏览器阻止了这种不安全的混合内容请求，导致图片无法显示

### 影响范围

- ❌ 图片上传后无法显示预览
- ❌ 图生视频功能无法使用（因为无法加载产品图片）
- ❌ 其他依赖图片 URL 的功能都会失败

---

## 解决方案

### 方案 1：修复代码并重启应用（推荐）

#### 步骤 1：代码已修复

代码已经更新，默认 URL 从 `http://47.110.72.148` 改为 `https://tnho-fasteners.com`

#### 步骤 2：在服务器上拉取最新代码

```bash
# SSH 登录服务器
ssh root@47.110.72.148

# 进入项目目录
cd /root/tnho-video

# 拉取最新代码
git pull origin main
```

#### 步骤 3：重启应用

**方法 1：使用重启脚本（推荐）**
```bash
cd /root/tnho-video
bash scripts/restart-app.sh
```

**方法 2：手动重启**
```bash
cd /root/tnho-video

# 停止旧进程
ps aux | grep "[u]vicorn app:app" | awk '{print $2}' | xargs kill

# 等待 2 秒
sleep 2

# 激活虚拟环境
source venv/bin/activate

# 启动新进程（后台运行）
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &

# 检查进程是否启动成功
ps aux | grep uvicorn
```

#### 步骤 4：验证修复

```bash
# 测试图片上传接口
curl -X POST https://tnho-fasteners.com/api/upload-image \
  -F "file=@/tmp/test.txt"
```

**预期结果**：
```json
{
  "success": true,
  "message": "图片上传成功",
  "image_url": "https://tnho-fasteners.com/assets/uploads/xxx.jpg",
  "filename": "xxx.jpg"
}
```

**注意**：`image_url` 应该以 `https://tnho-fasteners.com` 开头，而不是 `http://47.110.72.148`

### 方案 2：修改环境变量（临时方案）

如果无法立即重启应用，可以修改 `.env` 文件：

```bash
# SSH 登录服务器
ssh root@47.110.72.148

# 编辑 .env 文件
cd /root/tnho-video
nano .env

# 确保以下配置存在：
EXTERNAL_BASE_URL=https://tnho-fasteners.com

# 保存文件（Ctrl+O, Enter, Ctrl+X）

# 重启应用（见方案 1 的步骤 3）
```

---

## 验证修复结果

### 1. 测试图片上传

**在微信开发者工具中**：
1. 点击"上传图片"按钮
2. 选择一张图片
3. 观察控制台

**预期结果**：
- ✅ Console 显示"图片上传成功"
- ✅ 图片预览正常显示
- ✅ Network 标签显示请求成功（200 状态码）
- ✅ 没有红色错误信息

**Console 示例**：
```javascript
图片上传成功: {
  "success": true,
  "message": "图片上传成功",
  "image_url": "https://tnho-fasteners.com/assets/uploads/xxx.jpg",
  "filename": "xxx.jpg"
}
```

### 2. 测试图生视频

**测试步骤**：
1. 上传一张产品图片
2. 选择视频主题和时长
3. 点击"生成视频"按钮
4. 观察结果

**预期结果**：
- ✅ 进度条正常显示
- ✅ 生成的视频中包含产品元素
- ✅ 视频可以正常播放

### 3. 检查浏览器控制台

**在微信开发者工具中**：
- 打开 Console 标签
- 确认没有 Mixed Content 错误

**应该看到**：
```
✓ App: onLaunch have been invoked
✓ pages/index/index: onLoad have been invoked
✓ 图片上传成功: ...
```

**不应该看到**：
```
✗ Mixed Content: The page at ... was loaded over HTTPS,
  but requested an insecure image http://47.110.72.148/...
```

---

## 常见问题

### Q1: 重启应用后，图片 URL 还是使用 HTTP

**原因**：环境变量未正确加载

**解决方法**：
```bash
# 检查 .env 文件
cat /root/tnho-video/.env | grep EXTERNAL_BASE_URL

# 应该输出：
EXTERNAL_BASE_URL=https://tnho-fasteners.com

# 如果不是，编辑 .env 文件修改
nano /root/tnho-video/.env

# 重启应用
bash /root/tnho-video/scripts/restart-app.sh
```

### Q2: 重启应用后，小程序还是提示 Mixed Content 错误

**原因**：小程序缓存了旧的图片 URL

**解决方法**：
1. 在微信开发者工具中，点击"清除缓存" > "清除数据缓存"
2. 重新编译小程序
3. 重新测试图片上传功能

### Q3: 图片上传成功，但预览显示不出来

**原因**：
1. 图片 URL 使用了 HTTP 协议（本问题）
2. downloadFile 域名未配置
3. 图片文件未正确保存

**解决方法**：
1. 按照"解决方案"章节修复 Mixed Content 错误
2. 检查小程序后台 downloadFile 域名配置
3. 查看服务器日志：`tail -f /root/tnho-video/logs/app.log`

### Q4: 应用启动失败

**原因**：代码拉取失败或依赖问题

**解决方法**：
```bash
# 查看应用日志
tail -n 50 /root/tnho-video/logs/app.log

# 检查代码是否拉取成功
cd /root/tnho-video
git status

# 重新拉取代码
git pull origin main

# 重新安装依赖（如果需要）
source venv/bin/activate
pip install -r requirements.txt

# 重新启动应用
bash scripts/restart-app.sh
```

---

## 技术细节

### 代码修改

**修改文件**：`src/api/app.py`

**修改前**：
```python
# 获取外部访问的 base URL（从环境变量或默认值）
base_url = os.getenv("EXTERNAL_BASE_URL", "http://47.110.72.148")
```

**修改后**：
```python
# 获取外部访问的 base URL（从环境变量或默认值）
base_url = os.getenv("EXTERNAL_BASE_URL", "https://tnho-fasteners.com")
```

### 为什么必须使用 HTTPS？

1. **微信安全要求**：小程序必须使用 HTTPS 协议加载资源
2. **浏览器安全策略**：禁止 HTTPS 页面加载 HTTP 资源（Mixed Content）
3. **用户数据安全**：HTTPS 可以防止中间人攻击和数据窃取

### 域名 vs IP 地址

| 方式 | 优点 | 缺点 |
|------|------|------|
| 域名 | 支持 HTTPS、CDN 加速、SSL 证书 | 需要配置 DNS 解析 |
| IP 地址 | 直接访问、简单直接 | 不支持 HTTPS、无法配置 SSL 证书 |

---

## 相关文档

1. [小程序正式发布-快速测试指南](小程序正式发布-快速测试指南.md)
2. [小程序功能测试与诊断指南](小程序功能测试与诊断指南.md)
3. [服务器问题修复总结](服务器问题修复总结.md)

---

## 快速命令参考

### 在服务器上执行的命令

```bash
# 拉取最新代码
cd /root/tnho-video && git pull origin main

# 重启应用（使用脚本）
cd /root/tnho-video && bash scripts/restart-app.sh

# 重启应用（手动）
cd /root/tnho-video
ps aux | grep "[u]vicorn app:app" | awk '{print $2}' | xargs kill
sleep 2
source venv/bin/activate
nohup uvicorn app:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info >> logs/app.log 2>&1 &

# 查看应用日志
tail -f /root/tnho-video/logs/app.log

# 测试图片上传
curl -X POST https://tnho-fasteners.com/api/upload-image -F "file=@/tmp/test.txt"

# 查看进程状态
ps aux | grep uvicorn
```

### 在微信开发者工具中执行的步骤

1. 清除缓存 > 清除数据缓存
2. 重新编译小程序
3. 测试图片上传功能
4. 检查 Console 是否有错误

---

**文档版本**：1.0
**最后更新**：2026-01-14
**问题状态**：✅ 已修复
