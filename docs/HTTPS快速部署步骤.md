# HTTPS 快速部署步骤（5分钟搞定）

本指南帮助你快速配置 HTTPS 域名，将小程序部署到生产环境。

## 前置要求

### 必须完成的准备工作

#### 1. 购买域名
- 阿里云：https://wanwang.aliyun.com
- 腾讯云：https://cloud.tencent.com/product/domain
- 示例域名：`tnho-video.com`、`video.tnho.com`

#### 2. 域名备案（中国大陆必须）
- 登录阿里云/腾讯云控制台
- 进入 ICP 备案系统
- 提交备案信息（需要 1-20 个工作日审核）
- **注意：备案完成后才能部署**

#### 3. 域名解析配置
在域名服务商（阿里云/腾讯云）添加 A 记录：

| 主机记录 | 记录类型 | 记录值 | TTL |
|---------|---------|--------|-----|
| @       | A       | 47.110.72.148 | 600 |
| www     | A       | 47.110.72.148 | 600 |

#### 4. 检查域名解析
在服务器上执行：
```bash
ping your-domain.com
```
应该返回你的服务器 IP（47.110.72.148）

---

## 部署步骤

### 第 1 步：登录服务器

```bash
ssh root@47.110.72.148
```

### 第 2 步：进入项目目录

```bash
cd /workspace/projects
```

### 第 3 步：运行一键部署脚本

```bash
sudo bash scripts/quick-deploy-https.sh
```

### 第 4 步：按提示输入域名

脚本会提示你输入域名，例如：
```
请输入域名: tnho-video.com
确认吗？(y/n) y
```

### 第 5 步：等待自动配置

脚本会自动完成以下操作：
1. ✅ 安装 Certbot
2. ✅ 获取 SSL 证书
3. ✅ 更新 Nginx 配置
4. ✅ 更新小程序 API 地址
5. ✅ 重启服务
6. ✅ 配置证书自动续期

**大约需要 2-3 分钟**

### 第 6 步：验证部署

部署完成后，执行以下命令验证：

```bash
# 测试 HTTPS 连接
curl -I https://your-domain.com

# 测试 API 健康检查
curl https://your-domain.com/api/health

# 查看证书信息
certbot certificates
```

预期结果：
```
HTTP/2 200
server: nginx
...
```

---

## 配置微信小程序

### 步骤 1：登录微信公众平台

访问：https://mp.weixin.qq.com

### 步骤 2：配置服务器域名

**路径：** 开发管理 → 开发设置 → 服务器域名

### 步骤 3：添加 request 域名

在 **request 合法域名** 中添加：
```
https://your-domain.com
```

**注意事项：**
- ⚠️ 必须使用 HTTPS
- ⚠️ 域名必须备案
- ⚠️ 每月最多修改 5 次
- ⚠️ 需等待审核（5-10 分钟）

### 步骤 4：测试小程序

1. 打开微信开发者工具
2. 导入 `miniprogram` 目录
3. 点击 **编译**
4. 在模拟器中测试视频生成功能
5. 使用 **真机调试** 在手机上测试

---

## 常见问题

### Q1: 证书申请失败？

**错误信息：** `The requested hostname does not resolve to this server`

**解决方法：**
```bash
# 检查域名解析
ping your-domain.com

# 检查是否返回你的服务器 IP
dig your-domain.com

# 如果解析不正确，回到域名服务商重新配置 A 记录
```

### Q2: 80 端口被占用？

**错误信息：** `Problem binding to port 80: Could not bind to IPv4 or IPv6`

**解决方法：**
```bash
# 检查 80 端口占用
netstat -tuln | grep ':80 '

# 停止 Nginx 容器
docker-compose stop nginx

# 重新运行脚本
sudo bash scripts/quick-deploy-https.sh
```

### Q3: HTTPS 无法访问？

**检查步骤：**
```bash
# 1. 查看证书是否正确
certbot certificates

# 2. 检查 Nginx 配置
docker-compose exec nginx nginx -t

# 3. 查看 Nginx 日志
docker-compose logs nginx

# 4. 检查防火墙
sudo ufw status
```

### Q4: 小程序请求失败？

**可能原因：**
1. 微信后台域名配置错误
2. HTTPS 证书无效
3. API 地址未更新

**检查方法：**
1. 登录微信公众平台，确认域名已添加
2. 访问 https://www.ssllabs.com/ssltest/ 检查证书
3. 检查小程序 API 地址是否为 `https://your-domain.com`

---

## 证书自动续期

脚本已自动配置证书续期任务，每月 1 号凌晨 3 点自动续期。

### 手动续期测试

```bash
# 测试续期（不会实际续期）
sudo certbot renew --dry-run

# 手动续期
sudo certbot renew

# 查看续期日志
sudo cat /var/log/letsencrypt/letsencrypt.log
```

### 修改续期计划

```bash
sudo crontab -e
```

找到这一行：
```
0 3 1 * * certbot renew --quiet && docker-compose restart nginx
```

根据需要修改时间。

---

## 回滚到 HTTP（开发环境）

如果需要回滚到开发环境：

```bash
# 恢复原配置
cp nginx/nginx.conf.bak nginx/nginx.conf

# 重启服务
docker-compose restart nginx

# 更新小程序配置
sed -i "s|https://your-domain.com|http://47.110.72.148|g" miniprogram/app.js
sed -i "s|https://your-domain.com|http://47.110.72.148|g" miniprogram/pages/index/index.js
sed -i "s|https://your-domain.com|http://47.110.72.148|g" miniprogram/pages/result/result.js
```

---

## 完整部署清单

- [ ] 域名已购买
- [ ] 域名已完成备案
- [ ] 域名已解析到服务器 IP
- [ ] 在服务器上运行部署脚本
- [ ] HTTPS 连接测试通过
- [ ] API 接口测试通过
- [ ] 微信公众平台配置服务器域名
- [ ] 小程序功能测试通过
- [ ] 证书自动续期已配置

---

## 快速命令参考

```bash
# 查看证书
sudo certbot certificates

# 测试 HTTPS
curl -I https://your-domain.com

# 测试 API
curl https://your-domain.com/api/health

# 重启 Nginx
docker-compose restart nginx

# 查看 Nginx 日志
docker-compose logs -f nginx

# 查看证书续期计划
sudo crontab -l
```

---

## 技术支持

如有问题，请检查：
1. 域名是否正确解析
2. 80/443 端口是否开放
3. 防火墙是否阻止连接
4. 证书是否有效

---

**更新时间：** 2025-01-13
