# TNHO 服务器完整配置文档

## 问题诊断

### 当前问题

1. **小程序 API 请求失败**
   - 错误类型：403 Forbidden / Non-compliance ICP Filing
   - 原因：阿里云拦截未备案域名的请求

2. **HTTPS 访问问题**
   - Let's Encrypt 证书只为域名签发，不支持 IP 地址访问
   - Cloudflare SSL 模式配置问题

3. **Nginx 配置问题**
   - 端口配置不一致（配置文件中 8080，实际应用运行在 9000）
   - 缺少对 IP 地址的直接 HTTP 访问支持

## 架构说明

### 服务架构

```
用户请求 → Nginx (80/443) → FastAPI (9000) → PostgreSQL (Docker) → 火山方舟 API
```

### 端口说明

| 服务 | 端口 | 说明 |
|------|------|------|
| Nginx HTTP | 80 | 开发环境 IP 访问、生产域名重定向 |
| Nginx HTTPS | 443 | 生产环境域名 HTTPS 访问 |
| FastAPI | 9000 | 应用主端口 |
| PostgreSQL | 5432 | 数据库（Docker容器）|

### 访问方式

| 环境 | 协议 | 地址 | 说明 |
|------|------|------|------|
| 开发 | HTTP | http://47.110.72.148 | IP 访问，无需备案 |
| 生产 | HTTPS | https://tnho-fasteners.com | 域名访问，需 ICP 备案 |

## 解决方案

### 1. 修复 Nginx 配置

**目标**：
- 支持 IP 地址 HTTP 访问（开发环境）
- 支持域名 HTTPS 访问（生产环境）
- 统一反向代理端口为 9000

**配置文件位置**：`/etc/nginx/sites-available/tnho-https.conf`

**关键配置**：

```nginx
# HTTP 监听 - IP 地址直接访问（开发环境）
server {
    listen 80 default_server;
    server_name 47.110.72.148 _;
    
    location / {
        proxy_pass http://127.0.0.1:9000;
        # ... 其他配置
    }
}

# HTTPS 监听（生产环境）
server {
    listen 443 ssl http2;
    server_name tnho-fasteners.com;
    
    ssl_certificate /etc/letsencrypt/live/tnho-fasteners.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/tnho-fasteners.com/privkey.pem;
    # ... 其他配置
}
```

### 2. 开发环境临时方案

**原因**：
- 阿里云拦截未备案域名的请求
- HTTPS 证书不支持 IP 地址访问

**方案**：
- 使用 HTTP 协议访问 IP 地址
- Nginx 配置支持 IP 地址的 default_server

**小程序配置**：

```javascript
// miniprogram/app.js
globalData: {
  apiUrl: 'http://47.110.72.148',  // 开发环境
  // apiUrl: 'https://tnho-fasteners.com',  // 生产环境（需备案）
}
```

### 3. 生产环境正式方案

**前提条件**：
- 完成 ICP 备案（7-20 个工作日）
- 备案通过后更新小程序配置

**步骤**：
1. 准备备案材料（营业执照、身份证等）
2. 在阿里云提交备案申请
3. 等待审核
4. 备案通过后切换小程序 API 地址

## 部署步骤

### 方式一：使用自动化脚本（推荐）

```bash
# 在服务器上执行
cd /root/tnho-fasteners
chmod +x scripts/server_full_setup.sh
./scripts/server_full_setup.sh
```

脚本会自动完成以下步骤：
1. 检查项目目录
2. 检查 FastAPI 应用运行状态
3. 检查应用健康状态
4. 检查 Nginx 服务
5. 检查数据库运行状态
6. 部署 Nginx 配置文件
7. 创建 Nginx 配置符号链接
8. 检查 SSL 证书
9. 测试 Nginx 配置
10. 重启 Nginx 服务

### 方式二：手动部署

#### 步骤 1: 启动 FastAPI 应用

```bash
cd /root/tnho-fasteners

# 检查是否已有应用运行
ps aux | grep uvicorn

# 如果没有运行，启动应用
nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &

# 等待 3 秒
sleep 3

# 检查应用健康状态
curl http://127.0.0.1:9000/health
```

#### 步骤 2: 启动数据库（如果未运行）

```bash
cd /root/tnho-fasteners
docker-compose up -d db

# 检查数据库状态
docker ps | grep postgres
```

#### 步骤 3: 部署 Nginx 配置

```bash
# 复制配置文件
cp /root/tnho-fasteners/etc/nginx/sites-available/tnho-https.conf /etc/nginx/sites-available/

# 创建符号链接
ln -s /etc/nginx/sites-available/tnho-https.conf /etc/nginx/sites-enabled/

# 删除默认配置
rm -f /etc/nginx/sites-enabled/default
```

#### 步骤 4: 测试 Nginx 配置

```bash
nginx -t
```

#### 步骤 5: 重启 Nginx

```bash
nginx -s reload
```

#### 步骤 6: 验证服务

```bash
# 测试 HTTP IP 访问
curl http://47.110.72.148/health

# 测试 API 接口
curl http://47.110.72.148/api/themes

# 检查 Nginx 日志
tail -50 /var/log/nginx/error.log
```

## 验证清单

### 服务器端验证

- [ ] FastAPI 应用运行在 9000 端口
- [ ] 应用健康检查通过（/health 返回 200）
- [ ] PostgreSQL 数据库运行正常
- [ ] Nginx 服务运行正常
- [ ] Nginx 配置测试通过（nginx -t）
- [ ] HTTP IP 访问正常（curl http://47.110.72.148/health）
- [ ] API 接口可访问（curl http://47.110.72.148/api/themes）

### 小程序端验证

- [ ] 小程序 API 地址配置为 http://47.110.72.148
- [ ] 小程序请求超时时间为 30 秒
- [ ] 图片上传功能正常
- [ ] 视频生成功能正常
- [ ] 进度查询功能正常

## 监控命令

### 服务状态

```bash
# FastAPI 应用状态
ps aux | grep uvicorn

# 数据库状态
docker ps | grep postgres

# Nginx 状态
nginx -t
```

### 日志查看

```bash
# 应用日志
tail -50 /root/tnho-fasteners/app.log

# Nginx 错误日志
tail -50 /var/log/nginx/error.log

# Nginx 访问日志
tail -50 /var/log/nginx/access.log
```

### 端口监听

```bash
# 查看端口监听状态
netstat -tlnp | grep -E ":(80|443|9000|5432)"

# 或使用 ss 命令
ss -tlnp | grep -E ":(80|443|9000|5432)"
```

## 常见问题

### Q1: curl http://47.110.72.148/health 返回 301

**原因**：Nginx 配置问题，所有请求被重定向到 HTTPS

**解决**：确保 default_server 配置正确，不要对 IP 地址进行重定向

### Q2: 小程序请求返回 403

**原因**：阿里云拦截未备案域名的请求

**解决**：使用 IP 地址 HTTP 访问，或完成 ICP 备案

### Q3: Nginx 502 Bad Gateway

**原因**：FastAPI 应用未运行或端口配置错误

**解决**：
1. 检查应用是否运行：`ps aux | grep uvicorn`
2. 检查端口是否正确：`netstat -tlnp | grep 9000`
3. 检查 Nginx 配置端口是否匹配：`cat /etc/nginx/sites-available/tnho-https.conf`

### Q4: SSL 证书错误

**原因**：Let's Encrypt 证书未安装或已过期

**解决**：
1. 检查证书是否存在：`ls -la /etc/letsencrypt/live/tnho-fasteners.com/`
2. 如不存在，申请证书：`certbot certonly --nginx -d tnho-fasteners.com`
3. 如过期，续期证书：`certbot renew`

### Q5: 数据库连接失败

**原因**：PostgreSQL 容器未运行或配置错误

**解决**：
1. 检查容器状态：`docker ps | grep postgres`
2. 检查环境变量：`cat /root/tnho-fasteners/.env`
3. 重启容器：`docker-compose restart db`

## ICP 备案流程

### 准备材料

1. 企业营业执照（备案主体）
2. 法人身份证（正反面）
3. 网站负责人身份证（正反面）
4. 网站负责人手机号
5. 网站负责人邮箱
6. 网站负责人半身照片（背景白色）
7. 网站备案授权书（需加盖公章）

### 备案步骤

1. **登录阿里云备案系统**
   - 访问：https://beian.aliyun.com
   - 使用阿里云账号登录

2. **填写备案信息**
   - 填写主体信息（企业信息）
   - 填写网站信息（域名、服务器信息等）
   - 填写网站负责人信息

3. **上传资料**
   - 上传营业执照
   - 上传身份证照片
   - 上传半身照片
   - 上传授权书

4. **提交审核**
   - 提交到阿里云初审（1-2 个工作日）
   - 提交到管局审核（7-20 个工作日）

5. **备案通过**
   - 收到备案通过通知
   - 域名可以正常访问

### 备案后配置

```javascript
// 更新小程序配置（miniprogram/app.js）
globalData: {
  apiUrl: 'https://tnho-fasteners.com',  // 切换回域名
}
```

```nginx
# 更新 Cloudflare SSL 模式（生产环境）
# 从 Flexible 改为 Full
```

## 下一步行动

### 立即执行

1. 运行自动化脚本：`./scripts/server_full_setup.sh`
2. 验证服务：`curl http://47.110.72.148/health`
3. 测试小程序功能

### 近期执行

1. 准备 ICP 备案材料
2. 提交备案申请
3. 等待备案审核

### 长期规划

1. 备案通过后切换回域名 HTTPS 访问
2. 配置 Cloudflare Full SSL 模式
3. 配置 CDN 加速
4. 优化性能和安全性

## 联系方式

如有问题，请联系技术支持。

---

**文档版本**：1.0.0  
**最后更新**：2026-01-14  
**维护人员**：技术团队
