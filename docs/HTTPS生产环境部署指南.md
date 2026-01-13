# HTTPS 生产环境部署指南

本文档介绍如何将天虹视频生成小程序从开发环境部署到生产环境，包括 HTTPS 域名配置、SSL 证书获取和服务器配置。

## 目录

1. [前置要求](#前置要求)
2. [获取域名和 SSL 证书](#获取域名和-ssl-证书)
3. [配置 Nginx 支持 HTTPS](#配置-nginx-支持-https)
4. [更新小程序 API 地址](#更新小程序-api-地址)
5. [配置微信小程序服务器域名](#配置微信小程序服务器域名)
6. [测试和验证](#测试和验证)
7. [常见问题](#常见问题)

---

## 前置要求

- 已备案的域名（中国大陆必须）
- 阿里云/腾讯云服务器
- 服务器 root 权限
- Docker 和 Docker Compose 已安装

---

## 获取域名和 SSL 证书

### 方案一：使用 Let's Encrypt 免费证书（推荐）

**优点：** 免费、自动续期、配置简单

**步骤：**

1. 安装 Certbot
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx -y
```

2. 获取证书（替换为你的域名）
```bash
sudo certbot certonly --standalone -d your-domain.com --email admin@your-domain.com --agree-tos --non-interactive
```

3. 证书位置
- 证书：`/etc/letsencrypt/live/your-domain.com/fullchain.pem`
- 私钥：`/etc/letsencrypt/live/your-domain.com/privkey.pem`

### 方案二：使用阿里云/腾讯云免费证书

**优点：** 国内访问更快、适合企业用户

**步骤：**

1. 登录阿里云/腾讯云控制台
2. 搜索 **SSL 证书**
3. 申请免费证书（有效期 3 个月）
4. 下载证书文件（选择 Nginx 格式）
5. 上传到服务器
```bash
mkdir -p /etc/nginx/ssl
scp cert.pem root@your-server:/etc/nginx/ssl/
scp key.pem root@your-server:/etc/nginx/ssl/
```

---

## 配置 Nginx 支持 HTTPS

### 方法一：使用自动化配置脚本

```bash
sudo bash scripts/setup-https.sh
```

按照提示输入域名和选择 SSL 证书方案，脚本会自动配置。

### 方法二：手动配置

1. 编辑 `nginx/nginx.conf`

2. 替换域名（将 `your-domain.com` 替换为实际域名）

3. 根据选择的 SSL 方案，取消注释相应的证书配置：

**使用 Let's Encrypt:**
```nginx
ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
```

**使用阿里云/腾讯云证书:**
```nginx
ssl_certificate /etc/nginx/ssl/cert.pem;
ssl_certificate_key /etc/nginx/ssl/key.pem;
```

4. 确保证书目录已正确挂载到 Docker 容器

5. 重启 Nginx
```bash
docker-compose restart nginx
```

### 证书自动续期（Let's Encrypt）

设置定时任务自动续期证书：

```bash
# 编辑 crontab
sudo crontab -e

# 添加以下行（每月 1 号凌晨 3 点自动续期）
0 3 1 * * certbot renew --quiet && docker-compose restart nginx
```

---

## 更新小程序 API 地址

### 方法一：使用自动化脚本

```bash
bash scripts/update-miniprogram-api.sh
```

按照提示输入域名即可自动更新。

### 方法二：手动更新

更新以下三个文件中的 API 地址：

**1. miniprogram/app.js**
```javascript
// 开发环境
// apiUrl: 'http://47.110.72.148'

// 生产环境
apiUrl: 'https://your-domain.com'
```

**2. miniprogram/pages/index/index.js**
```javascript
// 开发环境
// const BASE_URL = 'http://47.110.72.148';

// 生产环境
const BASE_URL = 'https://your-domain.com';
```

**3. miniprogram/pages/result/result.js**
```javascript
// 开发环境
// const BASE_URL = 'http://47.110.72.148';

// 生产环境
const BASE_URL = 'https://your-domain.com';
```

---

## 配置微信小程序服务器域名

### 步骤 1：登录微信公众平台

访问：https://mp.weixin.qq.com

### 步骤 2：进入开发设置

**路径：** 开发管理 → 开发设置 → 服务器域名

### 步骤 3：配置 request 域名

在 **request 合法域名** 中添加：
```
https://your-domain.com
```

**注意事项：**
- 必须使用 HTTPS
- 域名必须备案
- 不支持 IP 地址
- 不支持端口号（默认 443）
- 每月最多修改 5 次

### 步骤 4：保存配置

点击 **保存并提交**，等待审核（通常 5-10 分钟）

---

## 测试和验证

### 1. 测试 HTTPS 连接

```bash
# 测试 HTTPS 是否正常工作
curl -I https://your-domain.com

# 应返回 200 OK 或 301/302 重定向
```

### 2. 测试 API 接口

```bash
# 测试健康检查接口
curl https://your-domain.com/api/health

# 测试视频生成接口
curl -X POST https://your-domain.com/api/generate-video \
  -H "Content-Type: application/json" \
  -d '{
    "product_name": "螺栓",
    "theme": "品质保证",
    "duration": 20,
    "generate_type": "video"
  }'
```

### 3. 测试小程序

1. 打开微信开发者工具
2. 导入 `miniprogram` 目录
3. 点击 **编译**
4. 在模拟器中测试：
   - 填写产品信息
   - 上传图片
   - 生成视频
   - 播放和下载视频
5. 使用 **真机调试** 功能在手机上测试

### 4. SSL 证书检查

使用在线工具检查 SSL 证书配置：
- https://www.ssllabs.com/ssltest/
- 输入你的域名，检查 SSL 配置是否正确
- 目标评分：A 或 A+

---

## 常见问题

### Q1: 证书获取失败？

**原因：**
- 域名未正确解析到服务器
- 80 端口被占用
- 防火墙阻止 80/443 端口

**解决方法：**
```bash
# 检查域名解析
dig your-domain.com

# 检查端口监听
netstat -tuln | grep -E ':(80|443)'

# 开放防火墙端口
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Q2: HTTPS 无法访问？

**检查项：**
1. 证书文件路径是否正确
2. Nginx 配置语法是否正确
3. Docker 容器是否正确挂载证书目录

**调试命令：**
```bash
# 查看 Nginx 日志
docker-compose logs nginx

# 测试 Nginx 配置
docker-compose exec nginx nginx -t

# 重启 Nginx
docker-compose restart nginx
```

### Q3: 小程序请求失败？

**可能原因：**
1. 域名未在微信后台配置
2. HTTPS 证书无效或过期
3. API 地址配置错误

**解决方法：**
1. 检查服务器域名配置是否正确
2. 使用在线工具检查 SSL 证书
3. 检查小程序 API 地址是否为 HTTPS

### Q4: Let's Encrypt 证书过期？

**自动续期：**
```bash
# 手动续期测试
sudo certbot renew --dry-run

# 查看续期日志
sudo cat /var/log/letsencrypt/letsencrypt.log
```

### Q5: 小程序审核被驳回？

**常见原因：**
1. 内容违规（包含敏感词、侵权内容）
2. 功能不完整
3. 缺少必要的用户协议

**解决方法：**
- 查看驳回原因
- 修改代码后重新上传
- 重新提交审核

---

## 部署检查清单

- [ ] 域名已备案
- [ ] SSL 证书已获取并配置
- [ ] Nginx 已配置 HTTPS
- [ ] 小程序 API 地址已更新为 HTTPS
- [ ] 微信公众平台已配置服务器域名
- [ ] HTTPS 连接测试通过
- [ ] API 接口测试通过
- [ ] 小程序功能测试通过
- [ ] SSL 证书检查通过
- [ ] 证书自动续期已配置

---

## 附录

### 快速部署命令

```bash
# 1. 获取 SSL 证书
sudo certbot certonly --standalone -d your-domain.com --email admin@your-domain.com --agree-tos --non-interactive

# 2. 更新 Nginx 配置
sed -i 's/your-domain.com/your-actual-domain.com/g' nginx/nginx.conf

# 3. 重启服务
docker-compose restart nginx

# 4. 更新小程序 API 地址
bash scripts/update-miniprogram-api.sh

# 5. 配置证书自动续期
(crontab -l 2>/dev/null; echo "0 3 1 * * certbot renew --quiet && docker-compose restart nginx") | crontab -
```

### 相关文档

- [小程序使用指南.md](../小程序使用指南.md)
- [快速开始.md](../快速开始.md)
- [Let's Encrypt 官方文档](https://letsencrypt.org/docs/)
- [微信小程序官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/server-ability/domain.html)

---

## 技术支持

如有问题，请联系：
- 技术支持邮箱：support@tnho.com
- 项目仓库：[GitHub](https://github.com/tnho/video-generator)

---

**最后更新：** 2025-01-13
