# HTTPS 配置完整指南

## 📋 配置前检查清单

在开始之前，请确认以下事项：

- [x] 域名已购买：`tnho-fasteners.com`
- [x] 域名已备案（中国大陆必须）
- [ ] 域名已解析到服务器 IP（47.110.72.148）
- [ ] 服务器上有 Root 权限

---

## 🔧 域名解析配置

### 第 1 步：登录域名服务商

登录你的域名服务商（阿里云、腾讯云等）

### 第 2 步：添加 DNS 解析记录

在域名解析管理中添加以下记录：

| 主机记录 | 记录类型 | 记录值 | TTL |
|---------|---------|--------|-----|
| @       | A       | 47.110.72.148 | 600 |
| www     | A       | 47.110.72.148 | 600 |

### 第 3 步：验证域名解析

在本地电脑上执行：
```bash
# Windows
ping tnho-fasteners.com

# Mac/Linux
ping tnho-fasteners.com
# 或
dig +short tnho-fasteners.com
```

应该返回服务器 IP：`47.110.72.148`

### 第 4 步：等待 DNS 生效

- 通常需要 5-10 分钟
- 最多可能需要 24 小时
- 可以使用 https://dnschecker.org/ 检查全球解析状态

---

## 🚀 HTTPS 自动配置

### 方案一：一键自动配置（推荐）

#### 在服务器上执行以下命令：

```bash
# 1. 登录服务器
ssh root@47.110.72.148

# 2. 进入项目目录
cd /workspace/projects

# 3. 赋予脚本执行权限
chmod +x scripts/setup-https.sh

# 4. 执行 HTTPS 配置脚本
sudo bash scripts/setup-https.sh
```

**脚本会自动完成：**
1. ✅ 检查域名解析
2. ✅ 检查容器状态
3. ✅ 停止 Nginx（释放 80 端口）
4. ✅ 安装 Certbot
5. ✅ 申请 Let's Encrypt SSL 证书
6. ✅ 更新 Nginx 配置
7. ✅ 重启 Nginx
8. ✅ 配置证书自动续期
9. ✅ 测试 HTTPS 访问

**预计时间：3-5 分钟**

---

### 方案二：手动分步配置

如果自动脚本失败，可以手动执行以下步骤：

#### 步骤 1: 安装 Certbot

```bash
sudo apt-get update
sudo apt-get install -y certbot
```

#### 步骤 2: 停止 Nginx

```bash
cd /workspace/projects
docker-compose stop nginx
```

#### 步骤 3: 申请 SSL 证书

```bash
sudo certbot certonly --standalone \
  -d tnho-fasteners.com \
  -d www.tnho-fasteners.com \
  --email admin@tnho-fasteners.com \
  --agree-tos \
  --non-interactive
```

#### 步骤 4: 验证证书

```bash
sudo certbot certificates
```

#### 步骤 5: 更新 Nginx 配置

编辑 `nginx/nginx.conf`，取消注释 HTTPS 配置部分：

```nginx
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com www.tnho-fasteners.com;

    # SSL 证书配置
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;

    # ... 其他配置
}
```

#### 步骤 6: 重启 Nginx

```bash
docker-compose restart nginx
```

#### 步骤 7: 配置证书自动续期

```bash
(crontab -l 2>/dev/null; echo "0 3 1 * * certbot renew --quiet && docker-compose restart nginx") | crontab -
```

---

## ✅ 验证 HTTPS 配置

### 1. 测试 HTTPS 访问

在本地电脑或服务器上执行：

```bash
# 测试 HTTPS 连接
curl -I https://tnho-fasteners.com

# 预期返回:
# HTTP/2 200
# server: nginx
# ...
```

### 2. 测试 API 健康检查

```bash
curl https://tnho-fasteners.com/health

# 预期返回:
# {"status":"ok"}
```

### 3. 检查证书

```bash
sudo certbot certificates
```

### 4. 在线 SSL 测试

访问 https://www.ssllabs.com/ssltest/
输入域名：`tnho-fasteners.com`

应该获得 A 或 A+ 评级

---

## 📱 更新小程序配置

### 第 1 步：更新 API 地址

在服务器上执行：

```bash
cd /workspace/projects
chmod +x scripts/update-miniprogram-api.sh
bash scripts/update-miniprogram-api.sh
```

或手动编辑 `miniprogram/app.js`：

```javascript
globalData: {
  systemInfo: null,
  apiUrl: 'https://tnho-fasteners.com'  // 改为 HTTPS 域名
}
```

### 第 2 步：重新编译小程序

1. 在微信开发者工具中，点击「编译」
2. 确认 API 地址已更新
3. 测试功能是否正常

### 第 3 步：取消「不校验合法域名」

- 点击「详情」→「本地设置」
- ❌ **取消勾选**「不校验合法域名、web-view（业务域名）、TLS版本以及HTTPS证书」

---

## 🌐 配置微信小程序服务器域名

### 第 1 步：登录微信公众平台

访问：https://mp.weixin.qq.com/

### 第 2 步：进入开发设置

开发管理 → 开发设置 → 服务器域名

### 第 3 步：添加合法域名

在以下域名类型中添加：

| 域名类型 | 域名 |
|---------|------|
| request 合法域名 | `https://tnho-fasteners.com` |
| uploadFile 合法域名 | `https://tnho-fasteners.com` |
| downloadFile 合法域名 | `https://tnho-fasteners.com` |

**注意事项：**
- ⚠️ 必须使用 HTTPS
- ⚠️ 域名必须备案
- ⚠️ 每月最多修改 5 次
- ⚠️ 需要等待审核（5-10 分钟）

### 第 4 步：等待审核

提交后等待审核通过（通常 5-10 分钟）

---

## 🧪 完整测试流程

### 1. 测试 API 连接

在微信开发者工具控制台执行：

```javascript
wx.request({
  url: 'https://tnho-fasteners.com/health',
  success(res) {
    console.log('API 连接成功', res.data)
  },
  fail(err) {
    console.error('API 连接失败', err)
  }
})
```

### 2. 测试脚本生成

- 产品名称：高强度螺栓
- 主题：品质保证
- 类型：脚本
- 点击「立即生成」

### 3. 测试图片上传

- 点击上传按钮
- 选择图片
- 验证上传成功

### 4. 测试视频生成

- 产品名称：不锈钢螺丝
- 主题：技术创新
- 类型：视频
- 时长：10秒
- 点击「立即生成」

### 5. 真机调试

- 点击「真机调试」
- 扫描二维码
- 在手机上测试所有功能

---

## 🐛 常见问题

### Q1: 域名解析检查失败？

**错误信息：** `域名解析不正确`

**解决方法：**
1. 检查 DNS 配置是否正确
2. 等待 DNS 生效（5-10 分钟）
3. 使用 dnschecker.org 检查全球解析状态
4. 确认 A 记录的值是 `47.110.72.148`

### Q2: SSL 证书申请失败？

**错误信息：** `The requested hostname does not resolve to this server`

**解决方法：**
```bash
# 检查域名解析
ping tnho-fasteners.com
dig +short tnho-fasteners.com

# 确保返回 47.110.72.148

# 检查 80 端口是否被占用
sudo netstat -tuln | grep ':80 '

# 如果被占用，停止占用 80 端口的服务
docker-compose stop nginx
```

### Q3: HTTPS 无法访问？

**检查步骤：**
```bash
# 1. 检查 Nginx 配置
docker-compose exec nginx nginx -t

# 2. 查看 Nginx 日志
docker-compose logs nginx

# 3. 检查证书
sudo certbot certificates

# 4. 测试端口
sudo netstat -tuln | grep ':443'
```

### Q4: 小程序请求失败？

**可能原因：**
1. 微信后台域名配置错误
2. HTTPS 证书无效
3. API 地址未更新

**检查方法：**
1. 登录微信公众平台，确认域名已添加
2. 访问 https://www.ssllabs.com/ssltest/ 检查证书
3. 检查 `app.js` 中的 API 地址是否为 `https://tnho-fasteners.com`

### Q5: 证书即将过期？

**证书自动续期已配置，每月1号凌晨3点自动续期**

手动续期：
```bash
sudo certbot renew
docker-compose restart nginx
```

---

## 📊 配置检查清单

- [ ] 域名已解析到 47.110.72.148
- [ ] SSL 证书申请成功
- [ ] HTTPS 访问正常
- [ ] API 健康检查通过
- [ ] 小程序 API 地址已更新
- [ ] 微信小程序服务器域名已配置
- [ ] 所有功能测试通过

---

## 📝 常用命令

```bash
# 查看证书
sudo certbot certificates

# 手动续期证书
sudo certbot renew

# 重启 Nginx
docker-compose restart nginx

# 查看 Nginx 日志
docker-compose logs -f nginx

# 查看容器状态
docker ps

# 查看所有日志
docker-compose logs -f

# 重启所有服务
docker-compose restart
```

---

## 🎯 配置完成后的访问地址

- **HTTP**: http://tnho-fasteners.com（自动跳转 HTTPS）
- **HTTPS**: https://tnho-fasteners.com
- **WWW**: https://www.tnho-fasteners.com
- **API**: https://tnho-fasteners.com/api/
- **健康检查**: https://tnho-fasteners.com/health

---

配置完成后，你的小程序就可以正式上线了！🎉
