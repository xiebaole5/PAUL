# TNHO Fasteners - HTTPS 部署指南

域名：**tnho-fasteners.com**

## 📋 部署清单

### 基础配置 ✅
- [x] 域名：tnho-fasteners.com
- [x] 服务器IP：47.110.72.148
- [x] Docker 环境已配置
- [x] Nginx 反向代理已配置
- [x] Docker Compose 已更新域名

### 待完成
- [ ] DNS 域名解析
- [ ] SSL 证书申请（推荐使用 Let's Encrypt）
- [ ] Nginx HTTPS 配置生效
- [ ] 微信小程序域名配置
- [ ] 小程序代码更新（使用 HTTPS）

---

## 🚀 部署步骤

### 第一步：域名解析

在你的域名服务商处添加 DNS 记录：

| 主机记录 | 记录类型 | 记录值 | TTL |
|---------|---------|--------|-----|
| @       | A       | 47.110.72.148 | 600 |
| www     | A       | 47.110.72.148 | 600 |

验证 DNS 解析：
```bash
ping tnho-fasteners.com
ping www.tnho-fasteners.com
```

预期返回你的服务器 IP（47.110.72.148）

---

### 第二步：SSL 证书申请（推荐使用 Let's Encrypt）

#### 方案 A：使用 Certbot 自动申请（推荐）

1. **安装 Certbot**
```bash
ssh root@47.110.72.148

# 更新系统包
apt update && apt upgrade -y

# 安装 certbot
apt install certbot python3-certbot-nginx -y
```

2. **申请 SSL 证书**
```bash
# 确保服务器 80 端口可访问
certbot certonly --standalone -d tnho-fasteners.com -d www.tnho-fasteners.com
```

按照提示输入邮箱并同意条款，证书将保存在：
```
/etc/letsencrypt/live/tnho-fasteners.com/
```

3. **设置证书自动续期**
```bash
# 添加自动续期任务
(crontab -l 2>/dev/null; echo "0 0 * * 0 certbot renew --quiet --deploy-hook 'docker restart tnho-nginx'") | crontab -
```

#### 方案 B：手动上传证书

1. **创建 SSL 目录**
```bash
mkdir -p /opt/tnho-video-generator/nginx/ssl
```

2. **上传证书文件**
将你的 SSL 证书文件上传到服务器：
- 证书文件：`/opt/tnho-video-generator/nginx/ssl/cert.pem`
- 私钥文件：`/opt/tnho-video-generator/nginx/ssl/key.pem`

3. **修改 docker-compose.yml**
```yaml
nginx:
  ...
  volumes:
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf
    - ./nginx/ssl:/etc/nginx/ssl:ro  # 启用此行
    - ./nginx/logs:/var/log/nginx
    - ./assets:/var/www/assets
```

---

### 第三步：配置 Nginx

Nginx 配置文件 `nginx/nginx.conf` 已经更新，包含：

#### HTTP 服务（端口 80）
- 基础功能：API 代理、静态文件服务
- Let's Encrypt 验证路径：`/.well-known/acme-challenge/`
- 自动跳转 HTTPS

#### HTTPS 服务（端口 443）
- SSL 证书配置
- 安全策略：TLS 1.2/1.3，强加密套件
- HSTS 支持
- API 代理（视频生成可能需要较长超时时间：600秒）
- 静态文件服务

---

### 第四步：重启服务

```bash
cd /opt/tnho-video-generator

# 停止并删除容器
docker stop tnho-video-api tnho-nginx
docker rm tnho-video-api tnho-nginx

# 重新启动容器
docker-compose up -d

# 等待服务启动
sleep 15

# 查看容器状态
docker ps

# 查看 Nginx 日志（检查 SSL 是否加载成功）
docker logs tnho-nginx
```

---

### 第五步：验证 HTTPS 配置

#### 1. 检查 HTTP 是否自动跳转 HTTPS
```bash
curl -I http://tnho-fasteners.com
```
预期返回：
```
HTTP/1.1 301 Moved Permanently
Location: https://tnho-fasteners.com/
```

#### 2. 检查 HTTPS 是否正常工作
```bash
curl -I https://tnho-fasteners.com
```
预期返回：
```
HTTP/2 200
...
```

#### 3. 检查 SSL 证书
```bash
echo | openssl s_client -servername tnho-fasteners.com -connect tnho-fasteners.com:443 2>/dev/null | openssl x509 -noout -dates
```

#### 4. 访问 API 健康检查
```bash
curl https://tnho-fasteners.com/health
```
预期返回：
```json
{"status":"ok"}
```

---

### 第六步：更新微信小程序

#### 1. 修改小程序配置文件

**miniprogram/app.js**
```javascript
globalData: {
  systemInfo: null,
  // 生产环境：使用 HTTPS
  apiUrl: 'https://tnho-fasteners.com'
}
```

#### 2. 在微信公众平台配置域名

1. 登录 [微信公众平台](https://mp.weixin.qq.com/)
2. 进入「开发」→「开发管理」→「开发设置」→「服务器域名」
3. 添加以下域名到「request 合法域名」：
   ```
   https://tnho-fasteners.com
   https://www.tnho-fasteners.com
   ```
4. 添加以下域名到「uploadFile 合法域名」：
   ```
   https://tnho-fasteners.com
   https://www.tnho-fasteners.com
   ```
5. 保存配置

**注意**：域名配置后可能需要几分钟生效。

---

### 第七步：测试小程序功能

1. 在微信开发者工具中打开小程序
2. 确保「不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书」选项关闭
3. 测试功能：
   - ✅ 图片上传
   - ✅ 脚本生成
   - ✅ 视频生成

---

## 🔧 常见问题排查

### 问题 1：SSL 证书加载失败

**症状**：访问 HTTPS 时提示证书错误或连接不安全

**排查步骤**：
```bash
# 检查证书文件是否存在
ls -la /etc/letsencrypt/live/tnho-fasteners.com/

# 检查 Nginx 配置
docker exec tnho-nginx nginx -t

# 查看 Nginx 错误日志
docker logs tnho-nginx
```

**解决方案**：
- 确保证书文件路径正确
- 重新申请证书
- 检查证书有效期

---

### 问题 2：HTTP 无法自动跳转 HTTPS

**症状**：访问 http://tnho-fasteners.com 不跳转

**排查步骤**：
```bash
# 检查 Nginx 配置
docker exec tnho-nginx cat /etc/nginx/nginx.conf | grep -A 10 "server_name"
```

**解决方案**：
- 确保 `nginx.conf` 中有 HTTP 301 跳转配置
- 重启 Nginx 容器：`docker restart tnho-nginx`

---

### 问题 3：小程序请求失败

**症状**：小程序显示「request:fail url not in domain list」

**解决方案**：
1. 在微信公众平台添加域名到合法域名列表
2. 等待几分钟让配置生效
3. 在开发者工具中清除缓存重新编译

---

### 问题 4：视频生成超时

**症状**：生成视频时提示「请求超时」

**解决方案**：
Nginx 已配置 600 秒超时，如果仍超时：
1. 检查网络连接
2. 查看容器日志：`docker logs tnho-video-api`
3. 确认火山方舟 API 可用

---

## 📊 配置信息总结

### 服务信息
| 项目 | 值 |
|-----|---|
| 域名 | tnho-fasteners.com |
| 服务器 IP | 47.110.72.148 |
| HTTPS 端口 | 443 |
| HTTP 端口 | 80 |

### 模型配置
| 类型 | 模型名称 |
|-----|---------|
| 文本处理 | doubao-1.8 |
| 视频生成 | doubao-seedance-1-5-pro |

### 访问地址
| 服务 | URL |
|-----|-----|
| API 服务 | https://tnho-fasteners.com |
| API 文档 | https://tnho-fasteners.com/docs |
| 健康检查 | https://tnho-fasteners.com/health |

---

## ✅ 部署完成后检查清单

- [ ] DNS 解析正常（ping 域名返回服务器 IP）
- [ ] SSL 证书已申请并配置
- [ ] HTTP 自动跳转 HTTPS
- [ ] HTTPS 访问正常
- [ ] API 健康检查通过
- [ ] 微信小程序域名已配置
- [ ] 小程序功能测试通过（图片上传、脚本生成、视频生成）
- [ ] 证书自动续期已配置

---

## 📞 技术支持

如遇到问题，请提供以下信息：
1. 错误截图或日志
2. 容器状态：`docker ps -a`
3. Nginx 日志：`docker logs tnho-nginx`
4. API 日志：`docker logs tnho-video-api`

---

**文档版本**: v1.1
**更新日期**: 2025-01-13
**域名**: tnho-fasteners.com
