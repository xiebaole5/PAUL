# 小程序 403 错误快速修复指南

## 问题现象

```
tnho-fasteners.com/api/generate-video:1 Failed to load resource: the server responded with a status of 403 ()
tnho-fasteners.com/api/upload-image:1 Failed to load resource: the server responded with a status of 403 ()
```

## ⚡ 快速解决方案（5分钟）

### 方法一：手动关闭 Bot Fight Mode（最简单）

1. 登录 https://dash.cloudflare.com/
2. 选择域名：**tnho-fasteners.com**
3. 左侧菜单点击：**Security（安全）** → **Settings（设置）**
4. 找到 **Bot fight mode**
5. 将 **JS Detections** 改为 **Off（关闭）**
6. 保存

### 方法二：使用自动化脚本

```bash
# 1. 设置 Cloudflare API 凭证
export CLOUDFLARE_API_TOKEN="你的API_Token"
export CLOUDFLARE_ZONE_ID="你的Zone_ID"

# 2. 运行修复脚本
cd /workspace/projects
python3 scripts/fix_cloudflare_security.py

# 3. 选择选项 1
```

## 如何获取 API Token 和 Zone ID？

### 获取 API Token

1. 访问：https://dash.cloudflare.com/profile/api-tokens
2. 点击 **Create Token**
3. 点击 **Use template** → 选择 **Edit zone DNS**
4. 点击 **Continue to summary**
5. 点击 **Create Token**
6. 复制生成的 Token（只显示一次！）

### 获取 Zone ID

1. 访问：https://dash.cloudflare.com/
2. 点击域名 **tnho-fasteners.com**
3. 在右侧边栏找到 **API** 部分
4. 复制 **Zone ID**

## 修复后验证

### 1. 清除小程序缓存

微信开发者工具 → 工具 → 清缓存 → 清除全部缓存

### 2. 重新编译

点击 **编译** 按钮

### 3. 测试功能

点击 **图片上传**，应该不再出现 403 错误

## 如果还是不行？

### 临时解决方案：直接访问服务器 IP

在小程序代码中临时修改 API 地址：

```javascript
// app.js 或 pages/index/index.js
const apiUrl = 'http://47.110.72.148:8080'; // 临时使用 IP 地址
```

**注意**：这只是测试方案，不能用于正式发布！

### 检查服务器是否正常

```bash
# 在服务器上测试
curl -I https://tnho-fasteners.com/health

# 应该返回 200 OK
```

## 为什么关闭域名校验也不行？

- ❌ 关闭域名校验：只是跳过微信的域名验证
- ❌ 请求仍然经过 Cloudflare CDN 代理
- ✅ Bot Fight Mode 在 Cloudflare 边缘节点拦截请求
- ✅ 发生在请求到达服务器之前

所以即使关闭域名校验，还是会被 Cloudflare 拦截！

## 详细文档

请查看完整的修复文档：

```bash
cat docs/CLOUDFLARE_SECURITY_FIX.md
```

## 需要帮助？

如果按照以上步骤操作后仍然无法解决，请提供：

1. Cloudflare 控制台的截图（Security 设置）
2. 小程序控制台的错误日志
3. 服务器 Nginx 日志：
   ```bash
   sudo tail -50 /var/log/nginx/access.log
   ```
