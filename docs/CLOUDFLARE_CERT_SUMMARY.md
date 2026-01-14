# Cloudflare Origin Certificate 配置 - 文件总结

## 📚 新增文件列表

### 📄 文档

1. **快速开始指南**：`QUICK_START_CLOUDFLARE_CERT.md`
   - 5 分钟快速配置指南
   - 适合新手快速上手

2. **详细部署文档**：`docs/CLOUDFLARE_CERT_DEPLOYMENT.md`
   - 完整的部署步骤
   - 包含两种部署方案（自动/手动）
   - 常见问题解决方案
   - 回滚方案

3. **配置说明**：`miniprogram/小程序问题排查指南.md`
   - 小程序无法打开的问题诊断
   - 4 种解决方案
   - 常见错误及解决方案

4. **快速修复配置**：`miniprogram/quick_fix_dev.js`
   - 开发环境快速修复配置
   - 可直接复制到 `app.js` 使用

### 🔧 脚本

1. **证书生成脚本**：`scripts/generate_cloudflare_cert.py`
   - 使用 Cloudflare API 自动生成证书
   - 支持 15 年有效期
   - 自动保存证书和私钥

   ```bash
   python scripts/generate_cloudflare_cert.py \
     --api-token YOUR_API_TOKEN \
     --domain tnho-fasteners.com
   ```

2. **证书部署脚本**：`scripts/deploy_cloudflare_cert.sh`
   - 自动上传证书到服务器
   - 自动备份现有证书
   - 自动测试 Nginx 配置
   - 自动重启 Nginx

   ```bash
   ./scripts/deploy_cloudflare_cert.sh \
     --cert certs/cloudflare-origin.crt \
     --key certs/cloudflare-origin.key
   ```

3. **服务器端部署脚本**：`scripts/server_deploy_cert.sh`
   - 在服务器上执行的部署脚本
   - 从 `/tmp` 目录读取证书文件
   - 自动完成所有部署步骤

   ```bash
   # 在服务器上执行
   bash scripts/server_deploy_cert.sh
   ```

4. **证书验证脚本**：`scripts/verify_cert.sh`
   - 验证证书是否正确部署
   - 显示证书详细信息
   - 测试 HTTPS 连接
   - 检查 Cloudflare 代理状态

   ```bash
   ./scripts/verify_cert.sh tnho-fasteners.com
   ```

---

## 🚀 快速使用

### 方式一：完整流程（推荐）

```bash
# 1. 生成证书
python scripts/generate_cloudflare_cert.py \
  --api-token YOUR_API_TOKEN \
  --domain tnho-fasteners.com

# 2. 部署证书
./scripts/deploy_cloudflare_cert.sh \
  --cert certs/cloudflare-origin.crt \
  --key certs/cloudflare-origin.key

# 3. 验证部署
./scripts/verify_cert.sh tnho-fasteners.com
```

### 方式二：使用服务器端脚本

```bash
# 本地执行
python scripts/generate_cloudflare_cert.py \
  --api-token YOUR_API_TOKEN \
  --domain tnho-fasteners.com

# 上传证书到服务器
scp certs/cloudflare-origin.crt root@47.110.72.148:/tmp/
scp certs/cloudflare-origin.key root@47.110.72.148:/tmp/

# SSH 登录服务器
ssh root@47.110.72.148

# 在服务器上执行部署脚本
bash /workspace/projects/scripts/server_deploy_cert.sh

# 验证证书
bash /workspace/projects/scripts/verify_cert.sh tnho-fasteners.com
```

---

## 📋 验证清单

部署完成后，请按以下清单验证：

### 本地验证

- [ ] 证书文件已生成：`certs/cloudflare-origin.crt`, `certs/cloudflare-origin.key`
- [ ] 证书文件已上传到服务器：`/etc/nginx/ssl/`
- [ ] Nginx 配置测试通过：`nginx -t`
- [ ] Nginx 服务已重启：`nginx -s reload`

### 服务器验证

- [ ] Nginx 服务运行正常：`ps aux | grep nginx`
- [ ] HTTPS 端口监听：`netstat -tlnp | grep :443`
- [ ] 证书信息正确：`openssl x509 -in /etc/nginx/ssl/tnho-origin.crt -noout -subject -issuer -dates`
- [ ] 本地 HTTPS 访问：`curl -k https://localhost/health`

### Cloudflare 验证

- [ ] SSL/TLS 模式为 `Full` 或 `Full (strict)`
- [ ] DNS 记录为 `Proxied`（橙色云朵）
- [ ] A 记录指向 47.110.72.148

### 公网验证

- [ ] 浏览器访问：https://tnho-fasteners.com
- [ ] 健康检查：https://tnho-fasteners.com/health
- [ ] 无证书警告

### 小程序验证

- [ ] API 地址配置：`https://tnho-fasteners.com`
- [ ] 微信开发者工具可以正常打开
- [ ] API 调用成功（无证书错误）

---

## 🔍 故障排查

### 问题 1：API Token 无权限

**解决方案**：
- 确认 Token 权限包含 `SSL and Certificates` -> `Edit`
- 确认 Token 对应正确的域名

### 问题 2：证书上传失败

**解决方案**：
- 检查 SSH 配置
- 使用密码认证：`ssh-copy-id root@47.110.72.148`

### 问题 3：Nginx 配置失败

**解决方案**：
- 检查证书文件完整性
- 检查私钥文件权限（600）
- 查看错误日志：`tail -f /var/log/nginx/error.log`

### 问题 4：浏览器仍显示警告

**解决方案**：
- 确认 Cloudflare SSL 模式为 `Full` 或 `Full (strict)`
- 清除浏览器缓存
- 使用隐身模式测试

### 问题 5：小程序仍无法访问

**解决方案**：
- 清除小程序缓存
- 检查 API 地址配置
- 临时关闭域名校验测试

---

## 📖 相关文档

- [快速开始指南](../QUICK_START_CLOUDFLARE_CERT.md)
- [详细部署文档](CLOUDFLARE_CERT_DEPLOYMENT.md)
- [HTTPS 配置完成说明](HTTPS_SETUP.md)
- [小程序问题排查指南](../miniprogram/小程序问题排查指南.md)

---

## 🆘 获取帮助

如果遇到问题：

1. 查看详细文档：`docs/CLOUDFLARE_CERT_DEPLOYMENT.md`
2. 检查脚本输出日志
3. 查看错误日志：`/var/log/nginx/error.log`
4. 验证证书：`./scripts/verify_cert.sh tnho-fasteners.com`

---

## 📝 注意事项

1. **备份重要**：部署脚本会自动备份现有证书，但建议手动备份
2. **测试先行**：使用 `--dry-run` 参数测试脚本执行
3. **逐步验证**：每完成一步都进行验证，不要一次性完成所有操作
4. **回滚准备**：了解回滚方案，以备不时之需

---

**创建时间**：2026-01-14 18:45
**版本**：v1.0.0
