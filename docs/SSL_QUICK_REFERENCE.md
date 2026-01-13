# Cloudflare SSL 证书快速参考

## 三种生成证书的方法

### 方法一：本地生成 + 上传（推荐）

**适用场景**：在本地电脑上生成证书，然后上传到服务器。

#### 步骤：

1. **生成证书**
   ```bash
   cd scripts
   python generate_cloudflare_cert.py \
     --api-token "YOUR_API_TOKEN" \
     --domain "tnho-fasteners.com"
   ```

2. **上传证书到服务器**
   ```bash
   # 创建目录
   ssh root@47.110.72.148 "mkdir -p /etc/nginx/ssl"

   # 上传证书
   scp certs/cloudflare-origin.pem root@47.110.72.148:/etc/nginx/ssl/
   scp certs/cloudflare-origin-key.pem root@47.110.72.148:/etc/nginx/ssl/

   # 设置权限
   ssh root@47.110.72.148 "chmod 600 /etc/nginx/ssl/cloudflare-origin-key.pem"
   ssh root@47.110.72.148 "chmod 644 /etc/nginx/ssl/cloudflare-origin.pem"
   ```

3. **重载 Nginx**
   ```bash
   ssh root@47.110.72.148 "nginx -t && systemctl reload nginx"
   ```

---

### 方法二：服务器端自动生成（最快）

**适用场景**：直接在服务器上运行脚本，自动生成并部署。

#### 步骤：

1. **上传脚本到服务器**
   ```bash
   scp scripts/generate_and_deploy_cert.sh root@47.110.72.148:/root/
   ```

2. **在服务器上运行**
   ```bash
   ssh root@47.110.72.148
   chmod +x /root/generate_and_deploy_cert.sh
   /root/generate_and_deploy_cert.sh
   ```

3. **按照提示输入**
   - Cloudflare API Token
   - 域名（默认: tnho-fasteners.com）
   - Zone ID（留空自动查找）

---

### 方法三：手动创建 + 部署脚本

**适用场景**：已在 Cloudflare 控制台生成证书，需要在服务器上部署。

#### 步骤：

1. **在 Cloudflare 控制台生成证书**
   - 登录 Cloudflare Dashboard
   - SSL/TLS -> Origin Server -> Create Certificate
   - 复制证书和私钥

2. **上传部署脚本**
   ```bash
   scp scripts/deploy_cloudflare_cert.sh root@47.110.72.148:/root/
   ```

3. **运行部署脚本**
   ```bash
   ssh root@47.110.72.148
   chmod +x /root/deploy_cloudflare_cert.sh
   /root/deploy_cloudflare_cert.sh
   ```

4. **按照提示粘贴**
   - 先粘贴证书内容（Ctrl+D 保存）
   - 再粘贴私钥内容（Ctrl+D 保存）

---

## 验证证书部署

### 本地测试
```bash
# 测试 HTTPS 访问
curl -I https://tnho-fasteners.com

# 查看 SSL 证书
curl -vI https://tnho-fasteners.com 2>&1 | grep -A 10 "SSL certificate"
```

### 浏览器测试
- 访问 `https://tnho-fasteners.com`
- 检查地址栏是否显示 🔒 锁图标
- 查看证书详情（应由 Cloudflare 签发）

---

## Cloudflare 配置清单

### DNS 配置
- [ ] A 记录: `tnho-fasteners.com` -> `47.110.72.148`
- [ ] CNAME 记录: `www.tnho-fasteners.com` -> `tnho-fasteners.com`
- [ ] 代理状态: **已代理**（橙色云 ☁️）

### SSL/TLS 配置
- [ ] 加密模式: **Full (strict)**
- [ ] Always Use HTTPS: **启用**
- [ ] Automatic HTTPS Rewrites: **启用**
- [ ] HSTS: 可选启用

---

## 故障排查

### 问题：访问显示 522 错误
```bash
# 检查防火墙
ufw status
ufw allow 443/tcp

# 检查 Nginx
systemctl status nginx
tail -f /var/log/nginx/error.log
```

### 问题：证书无效
```bash
# 检查证书文件
ls -la /etc/nginx/ssl/

# 验证证书
openssl x509 -in /etc/nginx/ssl/cloudflare-origin.pem -text -noout

# 检查 Nginx 配置
nginx -t
```

### 问题：Cloudflare 加密模式错误
- 确保 DNS 代理状态为"已代理"（橙色云）
- 确保加密模式为 **Full (strict)**

---

## 证书信息

### 证书详情
- **类型**: Cloudflare Origin Certificate (ECDSA)
- **有效期**: 15 年
- **域名**: tnho-fasteners.com, *.tnho-fasteners.com, www.tnho-fasteners.com
- **用途**: Cloudflare 到源服务器

### 文件位置
- **证书**: `/etc/nginx/ssl/cloudflare-origin.pem`
- **私钥**: `/etc/nginx/ssl/cloudflare-origin-key.pem`
- **备份**: `/etc/nginx/ssl/backup/`

---

## 更新证书

### 自动续期
```bash
# 运行生成脚本（覆盖旧证书）
/root/generate_and_deploy_cert.sh
```

### 手动续期
1. 在 Cloudflare 控制台生成新证书
2. 使用部署脚本上传新证书
3. 重载 Nginx

---

## 相关文档

- 详细部署指南: `docs/CLOUDFLARE_SSL_GUIDE.md`
- Nginx 配置: `nginx/nginx.conf`
- 生成脚本: `scripts/generate_cloudflare_cert.py`
- 部署脚本: `scripts/deploy_cloudflare_cert.sh`
- 一键脚本: `scripts/generate_and_deploy_cert.sh`
