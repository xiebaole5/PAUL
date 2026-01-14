# 天虹紧固件视频生成系统

> 基于 AI 的紧固件产品宣传视频和脚本生成系统

## 🎯 项目简介

本项目为浙江天虹紧固件有限公司开发的智能营销工具，通过 AI 技术快速生成专业的产品宣传视频和营销脚本。

### 核心功能

- 🎬 **AI 视频生成**：自动生成 5-30 秒的宣传视频
- 📝 **脚本生成**：生成专业营销脚本（含场景、文案、音效）
- 📷 **产品图片上传**：支持上传产品照片，生成更精准的视频
- 🎨 **多主题选择**：品质保证、技术创新、工业应用、品牌形象
- ⏱️ **时长定制**：5/10/15/20/25/30 秒六种时长
- 📱 **微信小程序**：便捷的用户交互界面

### 最新更新 🆕

**v1.1.0** - 新增图片上传和场景描述功能！
- ✅ 支持上传产品图片
- ✅ 支持详细的使用场景描述
- ✅ AI 根据图片和场景生成更精准的视频

详细说明请查看：[新功能说明文档](NEW_FEATURES_GUIDE.md)

---

## 🚀 快速开始

### 1. 解压项目

```bash
tar -xzf tnho-video-generator_v*.tar.gz
cd tnho-video-generator/
```

### 2. 安装依赖

```bash
pip install -r requirements.txt
```

### 3. 配置 API Key

创建 `.env` 文件：

```bash
ARK_API_KEY=your_api_key_here
```

### 4. 启动后端服务

```bash
chmod +x scripts/start_backend.sh
./scripts/start_backend.sh
```

### 5. 启动小程序

1. 打开微信开发者工具
2. 导入 `miniprogram` 目录
3. 配置后端地址：`http://localhost:8000`
4. 开始使用

---

## 📚 详细文档

### 部署和配置
- **[完整部署指南](DEPLOYMENT_GUIDE.md)** - 后端和小程序部署步骤
- **[项目总览](PROJECT_README.md)** - 项目结构和配置说明
- **[服务器快速配置](docs/服务器快速配置.md)** - 服务器环境搭建
- **[服务器问题修复总结](docs/服务器问题修复总结.md)** - 问题诊断和修复指南
- **[服务器问题诊断与修复指南](docs/服务器问题诊断与修复指南.md)** - 详细的修复步骤

### SSL 和 HTTPS
- **[SSL 证书快速参考](docs/SSL_QUICK_REFERENCE.md)** - Cloudflare SSL 证书配置（HTTPS）
- **[SSL 证书详细指南](docs/CLOUDFLARE_SSL_GUIDE.md)** - 完整的 SSL 证书部署教程
- **[Cloudflare SSL 配置指南](docs/cloudflare-ssl-配置指南.md)** - Cloudflare SSL/TLS 详细配置
- **[Nginx SSL 配置](docs/nginx-ssl-config.md)** - Nginx SSL 证书配置

### 小程序
- **[小程序使用说明](MINIPROGRAM_README.md)** - 小程序开发和调试
- **[小程序配置说明](miniprogram/小程序配置说明.md)** - 小程序配置详细说明
- **[小程序快速启动指南](miniprogram/快速启动指南.md)** - 小程序快速启动
- **[小程序正式发布指南](docs/小程序正式发布指南.md)** - 小程序发布流程
- **[小程序问题修复指南](miniprogram/问题修复指南.md)** - 常见问题解决

### 其他
- **[打包和下载指南](PACKAGE_GUIDE.md)** - 如何创建和分发项目包
- **[新功能说明](NEW_FEATURES_GUIDE.md)** - 图片上传和场景描述功能

---

## 🔒 HTTPS 配置

本项目已配置 HTTPS 访问，支持使用 Cloudflare Origin Certificate。

### 当前服务器状态

**服务器**：47.110.72.148
**域名**：tnho-fasteners.com
**状态**：✅ HTTPS 已启用

**服务状态**：
- HTTP (80 端口)：自动跳转到 HTTPS ✅
- HTTPS (443 端口)：正常提供服务 ✅
- 反向代理：正常转发到 FastAPI (8080) ✅
- 当前证书：自签名证书（临时，浏览器会警告）⚠️

### 管理命令

```bash
# 查看 Nginx 状态
./scripts/nginx.sh status

# 测试 HTTPS 访问
curl -k https://localhost/health

# 重启 Nginx
./scripts/nginx.sh restart

# 查看完整配置
./scripts/nginx.sh config
```

### 升级证书（推荐）

当前使用自签名证书，建议升级为 Cloudflare Origin Certificate 以消除浏览器警告。

### 🚀 快速配置（Cloudflare Origin Certificate）

**5 分钟快速配置：**

1. **获取 Cloudflare API Token**
   - 访问：https://dash.cloudflare.com/
   - 点击右上角头像 -> `My Profile` -> `API Tokens`
   - 点击 `Create Token`，选择 `Edit zone DNS` 模板
   - 配置权限：`Zone` -> `SSL and Certificates` -> `Edit`
   - 选择域名：`tnho-fasteners.com`
   - 点击 `Create Token`，**复制保存 Token**

2. **生成证书**
   ```bash
   pip install requests

   python scripts/generate_cloudflare_cert.py \
     --api-token YOUR_API_TOKEN \
     --domain tnho-fasteners.com
   ```

3. **部署证书**
   ```bash
   chmod +x scripts/deploy_cloudflare_cert.sh

   ./scripts/deploy_cloudflare_cert.sh \
     --cert certs/cloudflare-origin.crt \
     --key certs/cloudflare-origin.key
   ```

4. **配置 Cloudflare SSL**
   - 登录 https://dash.cloudflare.com/
   - 选择 `tnho-fasteners.com` 域名
   - 导航到 `SSL/TLS` -> `Overview`
   - 选择模式：`Full` 或 `Full (strict)`

5. **验证**
   ```bash
   curl -I https://tnho-fasteners.com
   curl https://tnho-fasteners.com/health
   ```

**详细文档：**
- [Cloudflare Origin Certificate 快速开始](QUICK_START_CLOUDFLARE_CERT.md)
- [Cloudflare Certificate 部署指南](docs/CLOUDFLARE_CERT_DEPLOYMENT.md)
- [HTTPS 配置完成说明](docs/HTTPS_SETUP.md)

### Cloudflare 配置

1. **DNS 配置**：
   - A 记录: `tnho-fasteners.com` -> `47.110.72.148`
   - 代理状态: **已代理**（橙色云）

2. **SSL/TLS 配置**：
   - 加密模式: **Full (strict)**
   - Always Use HTTPS: **启用**

详细说明请查看：[SSL 证书快速参考](docs/SSL_QUICK_REFERENCE.md)

---

## 📋 项目结构

```
.
├── src/              # 后端源代码
├── miniprogram/      # 微信小程序前端
├── config/           # 配置文件
├── scripts/          # 启动脚本
├── docs/             # 文档
└── requirements.txt  # Python 依赖
```

---

## 🛠️ 技术栈

- **后端**：Python 3.9+ + FastAPI + LangChain + LangGraph
- **AI 模型**：火山方舟 doubao-seedance（视频生成）、doubao-seed（LLM）
- **前端**：微信小程序原生开发

---

## 📞 技术支持

详细文档请查看：
- 部署问题：[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- 小程序问题：[MINIPROGRAM_README.md](MINIPROGRAM_README.md)

---

**开始使用，体验 AI 赋能的营销创作！🎉**
