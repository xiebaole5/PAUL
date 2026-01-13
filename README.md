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

- **[完整部署指南](DEPLOYMENT_GUIDE.md)** - 后端和小程序部署步骤
- **[小程序使用说明](MINIPROGRAM_README.md)** - 小程序开发和调试
- **[打包和下载指南](PACKAGE_GUIDE.md)** - 如何创建和分发项目包
- **[项目总览](PROJECT_README.md)** - 项目结构和配置说明
- **[SSL 证书快速参考](docs/SSL_QUICK_REFERENCE.md)** - Cloudflare SSL 证书配置（HTTPS）
- **[SSL 证书详细指南](docs/CLOUDFLARE_SSL_GUIDE.md)** - 完整的 SSL 证书部署教程

---

## 🔒 HTTPS 配置

本项目支持使用 Cloudflare Origin Certificate 配置 HTTPS。

### 快速配置

**方法一：服务器端自动生成（推荐）**
```bash
# 上传一键脚本
scp scripts/generate_and_deploy_cert.sh root@47.110.72.148:/root/

# SSH 登录服务器
ssh root@47.110.72.148

# 运行脚本
chmod +x /root/generate_and_deploy_cert.sh
/root/generate_and_deploy_cert.sh
```

**方法二：本地生成 + 上传**
```bash
# 本地生成证书
python scripts/generate_cloudflare_cert.py \
  --api-token "YOUR_API_TOKEN" \
  --domain "tnho-fasteners.com"

# 上传证书
scp certs/cloudflare-origin.pem root@47.110.72.148:/etc/nginx/ssl/
scp certs/cloudflare-origin-key.pem root@47.110.72.148:/etc/nginx/ssl/

# 重载 Nginx
ssh root@47.110.72.148 "nginx -t && systemctl reload nginx"
```

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
