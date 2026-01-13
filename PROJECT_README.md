# 天虹紧固件视频生成系统 - 完整项目包

## 📦 项目简介

本项目为浙江天虹紧固件有限公司开发的 AI 宣传视频生成系统，包含完整的后端服务和微信小程序前端。

### 核心功能

- 🎬 **AI 视频生成**：基于火山方舟 doubao-seedance 模型，自动生成 5-30 秒的宣传视频
- 📝 **脚本生成**：生成专业的营销视频脚本（含场景、文案、音效）
- 🎨 **多主题选择**：品质保证、技术创新、工业应用、品牌形象
- ⏱️ **时长定制**：5/10/15/20/25/30 秒六种时长
- 📱 **微信小程序**：便捷的用户交互界面
- 🔗 **FastAPI 后端**：高性能的 API 服务

---

## 📋 项目结构

```
tnho-video-generator/
├── src/                           # 后端源代码
│   ├── agents/                    # Agent 代码
│   │   └── agent.py               # 主 Agent 定义
│   ├── tools/                     # 工具代码
│   │   ├── video_generation_tool.py    # 视频生成工具
│   │   └── video_script_generator.py  # 脚本生成工具
│   ├── storage/                   # 存储模块
│   │   ├── memory/                # 记忆存储
│   │   ├── s3/                    # 对象存储
│   │   └── database/              # 数据库存储
│   ├── utils/                     # 工具函数
│   ├── api/                       # API 服务
│   │   └── app.py                 # FastAPI 主应用
│   └── main.py                    # 运行入口
│
├── miniprogram/                   # 微信小程序前端
│   ├── app.js                     # 小程序主入口
│   ├── app.json                   # 全局配置
│   ├── app.wxss                   # 全局样式
│   ├── project.config.json        # 项目配置
│   ├── pages/                     # 页面
│   │   └── index/                 # 首页
│   │       ├── index.js           # 页面逻辑
│   │       ├── index.json         # 页面配置
│   │       ├── index.wxml         # 页面结构
│   │       └── index.wxss         # 页面样式
│   └── sitemap.json               # 索引配置
│
├── config/                        # 配置文件
│   └── agent_llm_config.json      # Agent 配置
│
├── scripts/                       # 脚本工具
│   ├── start_backend.sh           # 后端启动脚本（Linux/Mac）
│   ├── start_backend.bat          # 后端启动脚本（Windows）
│   ├── package.sh                 # 项目打包脚本
│   └── ...                       # 其他脚本
│
├── docs/                          # 文档目录
│
├── tests/                         # 测试代码
│
├── dist/                          # 打包输出目录
│   ├── tnho-video-generator_v*.tar.gz  # 压缩包
│   ├── manifest.txt              # 文件清单
│   └── QUICKSTART.md              # 快速开始指南
│
├── requirements.txt               # Python 依赖
│
├── DEPLOYMENT_GUIDE.md            # 完整部署指南 ⭐
├── MINIPROGRAM_README.md          # 小程序使用说明 ⭐
├── PACKAGE_GUIDE.md               # 打包和下载指南 ⭐
└── PROJECT_README.md              # 本文件
```

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

### 3. 配置环境变量

创建 `.env` 文件（在项目根目录）：

```bash
# 必填：火山方舟 API Key
ARK_API_KEY=your_api_key_here

# 可选：对象存储配置
COZE_S3_ENDPOINT=https://s3.example.com
COZE_S3_ACCESS_KEY=your_access_key
COZE_S3_SECRET_KEY=your_secret_key
COZE_S3_BUCKET=your_bucket_name
```

**获取 API Key**：
- 登录 [火山方舟控制台](https://console.volcengine.com/ark)
- 创建应用并获取 API Key

### 4. 启动后端服务

```bash
# Linux/Mac
chmod +x scripts/start_backend.sh
./scripts/start_backend.sh

# Windows
scripts\start_backend.bat
```

服务启动后：
- API 地址：http://localhost:8000
- 健康检查：http://localhost:8000/health
- API 文档：http://localhost:8000/docs

### 5. 启动小程序

#### 开发环境

1. 下载并安装 [微信开发者工具](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)
2. 打开微信开发者工具
3. 选择「导入项目」
4. 选择 `miniprogram` 目录
5. AppID：开发阶段可选择「测试号」
6. 点击「导入」

#### 配置开发环境

在微信开发者工具中：
1. 点击右上角「详情」
2. 勾选「不校验合法域名、web-view、TLS 版本以及 HTTPS 证书」

#### 修改后端地址

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 开发环境：使用本地地址
    apiBaseUrl: 'http://localhost:8000'
  }
})
```

#### 开始使用

1. 在小程序中输入产品名称（如「高强度螺栓」）
2. 选择主题（品质保证、技术创新等）
3. 选择时长（5-30秒）
4. 点击「生成视频」
5. 等待 30-60 秒，查看生成的视频

---

## 📚 详细文档

### 部署文档

- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - 完整部署指南
  - 后端部署（本地、云服务器、Docker）
  - 小程序部署（开发、生产）
  - 常见问题解答

### 小程序文档

- **[MINIPROGRAM_README.md](MINIPROGRAM_README.md)** - 小程序使用说明
  - 开发环境配置
  - 调试技巧
  - 生产环境发布
  - 自定义样式

### 打包文档

- **[PACKAGE_GUIDE.md](PACKAGE_GUIDE.md)** - 打包和下载指南
  - 如何创建下载包
  - 如何分发项目
  - 用户接收后的步骤

---

## 🛠️ 技术栈

### 后端

- **Python 3.9+** - 编程语言
- **FastAPI** - Web 框架
- **LangChain 1.0** - AI 应用框架
- **LangGraph 1.0** - Agent 框架
- **doubao-seedance** - 视频生成模型
- **doubao-seed** - 大语言模型

### 前端

- **微信小程序原生开发** - 小程序框架
- **WXML** - 页面结构
- **WXSS** - 页面样式
- **JavaScript** - 逻辑处理

### 存储

- **对象存储（S3）** - 视频存储
- **PostgreSQL** - 数据存储（可选）
- **Memory** - 短期记忆

---

## 🔧 配置说明

### Agent 配置

`config/agent_llm_config.json`：

```json
{
  "config": {
    "model": "doubao-seed-1-6-251015",
    "temperature": 1,
    "max_completion_tokens": 50000,
    "timeout": 600
  },
  "sp": "Agent 系统提示词..."
}
```

### 小程序配置

`miniprogram/project.config.json`：

```json
{
  "appid": "your_appid_here",
  "projectname": "tnho-video-generator",
  "description": "天虹紧固件视频生成小程序"
}
```

---

## 🧪 测试

### 后端测试

```bash
# 运行单元测试
pytest tests/

# 运行 API 测试
pytest tests/test_api.py
```

### 手动测试

1. 启动后端服务
2. 打开微信开发者工具
3. 测试视频生成功能
4. 测试脚本生成功能

---

## 📦 打包分发

### 创建下载包

```bash
# 执行打包脚本
./scripts/package.sh

# 输出文件在 dist/ 目录
# - tnho-video-generator_v*.tar.gz
# - manifest.txt
# - QUICKSTART.md
```

### 分发方式

1. **直接下载**：将压缩包上传到文件服务器
2. **GitHub Release**：创建 GitHub Release 并上传附件
3. **私有下载**：使用云存储服务提供下载链接

详见 [PACKAGE_GUIDE.md](PACKAGE_GUIDE.md)

---

## 🌐 生产环境部署

### 后端部署

#### 云服务器部署

1. 购买云服务器（推荐配置：2核4G，Ubuntu 20.04）
2. 安装 Python 3.9+
3. 部署代码
4. 使用 Nginx 反向代理
5. 使用 PM2 管理进程
6. 配置 HTTPS（使用 Let's Encrypt）

#### Docker 部署

```bash
# 构建镜像
docker build -t tnho-api .

# 运行容器
docker run -d -p 8000:8000 \
  -e ARK_API_KEY=your_key \
  --name tnho-api \
  tnho-api
```

详见 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

### 小程序发布

1. 配置服务器域名白名单
2. 修改 `apiBaseUrl` 为生产地址
3. 在微信开发者工具中上传代码
4. 在微信公众平台提交审核
5. 审核通过后发布

---

## 📞 技术支持

### 文档资源

- [完整部署指南](DEPLOYMENT_GUIDE.md)
- [小程序使用说明](MINIPROGRAM_README.md)
- [打包和下载指南](PACKAGE_GUIDE.md)

### 常见问题

#### Q1: 后端启动失败

**检查清单**：
- Python 版本是否为 3.9+
- 依赖是否安装完整
- API Key 是否正确配置
- 端口 8000 是否被占用

#### Q2: 小程序无法连接后端

**解决方案**：
- 确认后端服务已启动
- 开发环境：启用「不校验合法域名」
- 生产环境：配置 HTTPS 域名
- 检查 `apiBaseUrl` 配置

#### Q3: 视频生成失败

**可能原因**：
- API Key 无效或额度不足
- 网络连接问题
- 模型调用超时

**解决方案**：
- 检查 API Key 配置
- 查看后端日志
- 增加超时时间

详见 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) 中的「常见问题」章节。

---

## 📝 更新日志

### v1.0.0 (2025-01-12)

- ✅ 初始版本发布
- ✅ AI 视频生成（5-30秒）
- ✅ 脚本生成功能
- ✅ 4种主题选择
- ✅ 微信小程序前端
- ✅ FastAPI 后端服务
- ✅ 完整文档和部署指南

---

## 📄 许可证

本项目为浙江天虹紧固件有限公司内部使用项目。

---

## 👥 开发团队

- 项目负责人：天虹紧固件
- 技术支持：Coze Coding

---

## 🎉 开始使用

现在你已经了解了整个项目，可以：

1. 阅读快速开始指南，部署项目
2. 查看 [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) 了解详细部署步骤
3. 查看 [MINIPROGRAM_README.md](MINIPROGRAM_README.md) 了解小程序使用方法

**祝使用愉快！🚀**
