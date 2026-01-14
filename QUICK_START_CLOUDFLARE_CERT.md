# Cloudflare Origin Certificate 快速开始指南

## 🚀 5 分钟快速配置

### 前置条件

- [x] Cloudflare 账号
- [x] 域名已托管在 Cloudflare
- [x] 服务器 SSH 访问权限

---

## 📝 步骤 1：获取 API Token（2 分钟）

1. 访问：https://dash.cloudflare.com/
2. 点击右上角头像 -> `My Profile` -> `API Tokens`
3. 点击 `Create Token`
4. 选择 `Edit zone DNS` 模板
5. 配置权限：
   - `Zone` -> `SSL and Certificates` -> `Edit`
   - `Zone Resources` -> `Include` -> `Specific zone` -> `tnho-fasteners.com`
6. 点击 `Create Token`
7. **复制保存 Token**（只显示一次）

---

## 📝 步骤 2：生成证书（1 分钟）

```bash
# 安装依赖
pip install requests

# 生成证书（替换 YOUR_API_TOKEN）
python scripts/generate_cloudflare_cert.py \
  --api-token YOUR_API_TOKEN \
  --domain tnho-fasteners.com
```

**输出文件**：
- `certs/cloudflare-origin.crt`（证书）
- `certs/cloudflare-origin.key`（私钥）

---

## 📝 步骤 3：部署证书（1 分钟）

```bash
# 设置执行权限
chmod +x scripts/deploy_cloudflare_cert.sh

# 部署证书
./scripts/deploy_cloudflare_cert.sh \
  --cert certs/cloudflare-origin.crt \
  --key certs/cloudflare-origin.key
```

脚本会自动：
- 备份现有证书
- 上传新证书
- 测试 Nginx 配置
- 重启 Nginx

---

## 📝 步骤 4：配置 Cloudflare SSL（1 分钟）

1. 访问：https://dash.cloudflare.com/
2. 选择 `tnho-fasteners.com` 域名
3. 导航到 `SSL/TLS` -> `Overview`
4. 选择模式：`Full` 或 `Full (strict)`

---

## 📝 步骤 5：验证（1 分钟）

```bash
# 测试 HTTPS 访问
curl -I https://tnho-fasteners.com

# 测试健康检查
curl https://tnho-fasteners.com/health
```

预期结果：
- 返回状态码 200
- 无证书错误

---

## ✅ 完成！

现在可以：
1. 在微信开发者工具中打开小程序
2. 刷新小程序
3. 测试 API 调用

应该可以正常访问了，不再出现证书错误！

---

## 🆘 遇到问题？

详细文档：[Cloudflare Certificate 部署指南](docs/CLOUDFLARE_CERT_DEPLOYMENT.md)

常见问题：
- API Token 无权限 -> 检查 Token 权限配置
- 证书上传失败 -> 检查 SSH 配置
- Nginx 配置失败 -> 检查证书文件完整性
- 浏览器显示警告 -> 检查 Cloudflare SSL 模式
- 小程序仍无法访问 -> 清除小程序缓存

---

**所需时间**：约 5 分钟
**难度**：⭐⭐☆☆☆（简单）

💡 **提示**：如果遇到问题，可以随时回滚到之前的配置，详见部署文档的回滚方案。
