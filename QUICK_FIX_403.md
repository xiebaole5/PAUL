# TNHO 问题完整解决方案

## 问题总结

### 核心问题

1. **小程序 API 请求失败**
   - 错误：403 Forbidden / Non-compliance ICP Filing
   - 原因：阿里云拦截未备案域名的请求

2. **HTTPS 访问限制**
   - Let's Encrypt 证书只为域名签发，不支持 IP 地址访问
   - Cloudflare SSL 模式配置问题（Full 模式导致 525 错误）

3. **Nginx 配置问题**
   - 端口配置不一致（配置文件中 8080，实际应用运行在 9000）
   - 缺少对 IP 地址的直接 HTTP 访问支持
   - 所有 HTTP 请求被重定向到 HTTPS，导致 IP 访问失败

### 技术分析

```
问题链路分析：

用户请求（小程序）
    ↓
微信小程序服务器
    ↓
DNS 解析（tnho-fasteners.com → Cloudflare IP）
    ↓
Cloudflare CDN（Bot Fight Mode 阻止 → 已关闭）
    ↓
阿里云 CDN/防火墙（ICP 备案检查 → 阻止未备案域名）
    ↓
Nginx 反向代理（80 → 9000）
    ↓
FastAPI 应用（9000）
    ↓
PostgreSQL 数据库
    ↓
火山方舟 API
```

## 解决方案

### 方案概述

**开发环境**（当前使用）：
- 使用 HTTP 协议访问 IP 地址
- 绕过 Cloudflare CDN 和阿里云 ICP 备案检查
- 配置 Nginx 支持 IP 地址的 default_server

**生产环境**（备案完成后）：
- 使用 HTTPS 协议访问域名
- 完成 ICP 备案后启用
- 配置 Cloudflare Full SSL 模式

### 具体实施

#### 步骤 1: 修复 Nginx 配置

**目标**：支持 IP 地址 HTTP 访问和域名 HTTPS 访问

**配置文件**：`/etc/nginx/sites-available/tnho-https.conf`

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

#### 步骤 2: 部署配置

**自动化脚本**：`scripts/server_full_setup.sh`

```bash
# 在服务器上执行
cd /root/tnho-fasteners
chmod +x scripts/server_full_setup.sh
./scripts/server_full_setup.sh
```

**脚本功能**：
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

#### 步骤 3: 修复小程序配置

**配置文件**：`miniprogram/app.js`

**关键配置**：
```javascript
globalData: {
  // 开发环境（当前使用）
  apiUrl: 'http://47.110.72.148',

  // 生产环境（ICP 备案完成后使用）
  // apiUrl: 'https://tnho-fasteners.com',
}
```

#### 步骤 4: 验证服务

**测试命令**：
```bash
# 测试健康检查
curl http://47.110.72.148/health

# 测试 API 接口
curl http://47.110.72.148/api/themes

# 测试图片上传
curl -X POST http://47.110.72.148/api/upload-image \
  -F "file=@/tmp/test.jpg"
```

**自动化测试**：`scripts/quick_test.sh`

```bash
# 在服务器上执行
cd /root/tnho-fasteners
chmod +x scripts/quick_test.sh
./quick_test.sh
```

#### 步骤 5: 问题排查

**排查脚本**：`scripts/diagnose.sh`

```bash
# 在服务器上执行
cd /root/tnho-fasteners
chmod +x scripts/diagnose.sh
./diagnose.sh
```

**排查功能**：
1. 系统资源检查
2. FastAPI 应用检查
3. FastAPI 健康检查
4. FastAPI API 接口检查
5. PostgreSQL 数据库检查
6. 数据库连接检查
7. Nginx 服务检查
8. Nginx 运行状态检查
9. Nginx 配置检查
10. Nginx 端口监听检查
11. HTTP IP 访问检查
12. SSL 证书检查
13. 环境变量检查
14. 日志文件检查
15. 快速功能测试

## 文件清单

### 生成的文件

| 文件路径 | 用途 |
|---------|------|
| `/etc/nginx/sites-available/tnho-https.conf` | Nginx 配置文件 |
| `scripts/server_full_setup.sh` | 服务器完整配置脚本 |
| `scripts/diagnose.sh` | 问题排查脚本 |
| `scripts/quick_test.sh` | 快速测试脚本 |
| `docs/SERVER_FULL_SETUP.md` | 服务器配置文档 |
| `miniprogram/app_fix.js` | 小程序配置修复文件 |
| `QUICK_FIX_403.md` | 快速修复指南（本文档） |

### 需要手动操作的文件

| 文件路径 | 操作 |
|---------|------|
| `miniprogram/app.js` | 更新 `apiUrl` 为 `http://47.110.72.148` |
| `pages/index/index.js` | 确保使用 `getApp().globalData.apiUrl` |

## 操作步骤

### 1. 服务器端操作

```bash
# SSH 登录服务器
ssh root@47.110.72.148

# 进入项目目录
cd /root/tnho-fasteners

# 运行完整配置脚本
chmod +x scripts/server_full_setup.sh
./scripts/server_full_setup.sh

# 运行快速测试
chmod +x scripts/quick_test.sh
./quick_test.sh

# 如有问题，运行排查脚本
chmod +x scripts/diagnose.sh
./diagnose.sh
```

### 2. 小程序端操作

1. 打开微信开发者工具
2. 打开 `miniprogram/app.js`
3. 更新 `globalData.apiUrl` 为 `http://47.110.72.148`
4. 保存文件
5. 重新编译小程序
6. 测试图片上传和视频生成功能

### 3. 测试验证

**服务器端测试**：
```bash
# 健康检查
curl http://47.110.72.148/health

# 主题列表
curl http://47.110.72.148/api/themes

# 图片上传（需要准备图片文件）
curl -X POST http://47.110.72.148/api/upload-image \
  -F "file=@/tmp/test.jpg"
```

**小程序端测试**：
1. 测试图片上传功能
2. 测试视频生成功能
3. 测试进度查询功能
4. 测试视频播放功能

## 验证清单

### 服务器端

- [ ] FastAPI 应用运行在 9000 端口
- [ ] 应用健康检查通过（/health 返回 200）
- [ ] PostgreSQL 数据库运行正常
- [ ] Nginx 服务运行正常
- [ ] Nginx 配置测试通过（nginx -t）
- [ ] HTTP IP 访问正常（curl http://47.110.72.148/health）
- [ ] API 接口可访问（curl http://47.110.72.148/api/themes）
- [ ] 图片上传功能正常
- [ ] 视频生成功能正常
- [ ] 进度查询功能正常

### 小程序端

- [ ] 小程序 API 地址配置为 `http://47.110.72.148`
- [ ] 小程序请求超时时间为 30 秒
- [ ] 图片上传功能正常
- [ ] 视频生成功能正常
- [ ] 进度查询功能正常
- [ ] 视频播放功能正常

### 真机调试

- [ ] 在微信开发者工具中关闭域名校验（开发阶段）
- [ ] 小程序真机调试可以正常访问 API
- [ ] 图片上传功能在真机上正常
- [ ] 视频生成功能在真机上正常

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

**更新小程序配置**：
```javascript
// miniprogram/app.js
globalData: {
  apiUrl: 'https://tnho-fasteners.com',  // 切换回域名
}
```

**更新 Cloudflare SSL 模式**：
- 从 Flexible 改为 Full

**配置微信小程序合法域名**：
- request: https://tnho-fasteners.com
- uploadFile: https://tnho-fasteners.com
- downloadFile: https://tnho-fasteners.com

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

**解决**：
```bash
# 检查 Nginx 配置
cat /etc/nginx/sites-available/tnho-https.conf

# 确保配置中有 default_server
# 运行配置脚本
./scripts/server_full_setup.sh
```

### Q2: 小程序请求返回 403

**原因**：阿里云拦截未备案域名的请求

**解决**：
- 开发环境：使用 IP 地址 HTTP 访问
- 生产环境：完成 ICP 备案

### Q3: Nginx 502 Bad Gateway

**原因**：FastAPI 应用未运行或端口配置错误

**解决**：
```bash
# 检查应用是否运行
ps aux | grep uvicorn

# 检查端口是否正确
netstat -tlnp | grep 9000

# 启动应用
cd /root/tnho-fasteners
nohup python3 -m uvicorn app.main:app --host 0.0.0.0 --port 9000 > app.log 2>&1 &
```

### Q4: 小程序提示 "不在以下 request 合法域名列表中"

**原因**：小程序域名校验开启

**解决**：
- 开发阶段：在微信开发者工具中关闭域名校验
- 生产阶段：在微信小程序后台配置合法域名

### Q5: 图片上传失败

**原因**：Nginx 配置问题或文件大小限制

**解决**：
```bash
# 检查 Nginx 配置
cat /etc/nginx/sites-available/tnho-https.conf | grep client_max_body_size

# 确保配置为 10M
client_max_body_size 10M;

# 重新加载 Nginx
nginx -s reload
```

### Q6: 视频生成失败

**原因**：火山方舟 API Key 错误或网络问题

**解决**：
```bash
# 检查 API Key
cat /root/tnho-fasteners/.env | grep ARK_API_KEY

# 查看应用日志
tail -100 /root/tnho-fasteners/app.log
```

## 下一步行动

### 立即执行

- [ ] 运行服务器配置脚本：`./scripts/server_full_setup.sh`
- [ ] 运行快速测试：`./scripts/quick_test.sh`
- [ ] 验证 HTTP IP 访问：`curl http://47.110.72.148/health`
- [ ] 更新小程序配置：`apiUrl: 'http://47.110.72.148'`
- [ ] 测试小程序功能

### 近期执行

- [ ] 准备 ICP 备案材料
- [ ] 提交备案申请
- [ ] 等待备案审核（7-20 个工作日）

### 长期规划

- [ ] 备案通过后切换回域名 HTTPS 访问
- [ ] 配置 Cloudflare Full SSL 模式
- [ ] 配置 CDN 加速
- [ ] 优化性能和安全性

## 总结

### 问题根源

1. 阿里云拦截未备案域名的请求
2. HTTPS 证书不支持 IP 地址访问
3. Nginx 配置缺少对 IP 地址的直接 HTTP 访问支持

### 解决方案

1. 配置 Nginx 支持 IP 地址 HTTP 访问（default_server）
2. 小程序使用 IP 地址 HTTP 访问（开发环境）
3. 完成 ICP 备案后切换回域名 HTTPS 访问（生产环境）

### 关键文件

- Nginx 配置：`/etc/nginx/sites-available/tnho-https.conf`
- 服务器配置脚本：`scripts/server_full_setup.sh`
- 问题排查脚本：`scripts/diagnose.sh`
- 快速测试脚本：`scripts/quick_test.sh`
- 小程序配置：`miniprogram/app.js`

### 验证方法

```bash
# 服务器端测试
curl http://47.110.72.148/health

# 小程序端测试
1. 图片上传功能
2. 视频生成功能
3. 进度查询功能
4. 视频播放功能
```

## 联系方式

如有问题，请参考以下资源：

- 服务器配置文档：`docs/SERVER_FULL_SETUP.md`
- 问题排查脚本：`scripts/diagnose.sh`
- 快速测试脚本：`scripts/quick_test.sh`
- 小程序配置修复：`miniprogram/app_fix.js`

---

**文档版本**：1.0.0
**最后更新**：2026-01-14
**维护人员**：技术团队
