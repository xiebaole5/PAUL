# 本地开发环境 - 企业微信验证

## 🎯 方案说明

放弃阿里云服务器，使用**本地开发 + ngrok内网穿透**的方案。

**优势：**
- ✅ 快速开发和调试
- ✅ 无需服务器配置
- ✅ 自动支持HTTPS
- ✅ 实时查看日志

---

## 📋 前置条件

### 必需工具
1. **Python 3.12+**
   - 访问 https://www.python.org/downloads/ 下载

2. **FastAPI + Uvicorn**
   ```bash
   pip install fastapi uvicorn pydantic python-dotenv
   ```

3. **ngrok**
   - 注册账号: https://ngrok.com/
   - 下载: https://ngrok.com/download
   - 配置authtoken:
     ```bash
     ngrok config add-authtoken YOUR_AUTH_TOKEN
     ```

---

## 🚀 快速开始（3步）

### 步骤1：检查环境

**Linux/macOS:**
```bash
bash check_local_env.sh
```

**Windows:**
```cmd
check_local_env.bat
```

### 步骤2：启动服务

**终端1 - 启动FastAPI:**
```bash
# Linux/macOS
bash start_local.sh

# Windows
start_local.bat
```

**终端2 - 启动ngrok:**
```bash
# Linux/macOS
bash start_ngrok.sh

# Windows
start_ngrok.bat
```

**复制ngrok提供的HTTPS URL**，例如：
```
https://abcd-1234-5678.ngrok-free.app
```

### 步骤3：配置企业微信

在企业微信管理后台：

```
回调URL: https://abcd-1234-5678.ngrok-free.app/api/wechat/callback
Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
```

点击"验证"按钮。

---

## 📚 文档清单

| 文件 | 说明 | 适用场景 |
|------|------|----------|
| `QUICKSTART.md` | 快速启动指南 | 3分钟快速上手 |
| `LOCAL_SETUP_GUIDE.md` | 完整安装指南 | 详细安装步骤 |
| `ENTERPRISE_WECHAT_EXPLAINED.md` | 企业微信架构说明 | 理解工作原理 |
| `README_LOCAL.md` | 本地开发总览 | 当前文档 |

## 🛠️ 脚本清单

### Linux/macOS
| 脚本 | 功能 |
|------|------|
| `check_local_env.sh` | 检查本地环境 |
| `start_local.sh` | 启动FastAPI服务 |
| `start_ngrok.sh` | 启动ngrok隧道 |

### Windows
| 脚本 | 功能 |
|------|------|
| `check_local_env.bat` | 检查本地环境 |
| `start_local.bat` | 启动FastAPI服务 |
| `start_ngrok.bat` | 启动ngrok隧道 |

---

## 🔍 监控和调试

### 查看FastAPI日志
在启动FastAPI的终端中查看实时日志。

### 查看ngrok请求
打开浏览器访问：
```
http://localhost:4040
```

你可以看到：
- 所有传入的HTTP请求
- 请求头、响应头
- 请求体、响应体

---

## ⚠️ 注意事项

### ngrok免费版限制
- URL每次重启会变化
- 有并发连接限制
- 有带宽限制

**解决方案：**
- 开发阶段使用ngrok
- 验证成功后部署到正式服务器

### 安全提醒
- ngrok URL是公开的，任何人都可以访问
- 生产环境请使用正式域名和服务器

---

## ❓ 常见问题

### Q1: ngrok命令未找到？
A: 确保ngrok已正确安装并添加到PATH环境变量。

### Q2: 端口被占用？
A: 脚本会自动检测并使用备用端口8001。

### Q3: 企业微信验证失败？
A:
1. 确认使用HTTPS URL
2. 检查Token是否正确
3. 查看ngrok面板（http://localhost:4040）
4. 查看FastAPI服务日志

### Q4: 如何停止服务？
A: 在对应的终端中按 `Ctrl+C`

---

## 📝 配置信息

### 企业微信配置
```
回调URL: https://[ngrok-url]/api/wechat/callback
Token: gkIzrwgJI041s52TPAszz2j5iGnpZ4
EncodingAESKey: 2pCDTnGuFB0s8Ianv7WDzhfcyMnmlwb65KDnAbXNFCr
Corp ID: ww4564cfcc6de70e6c
```

### 服务端口
```
FastAPI: 8000 (默认) 或 8001 (备用)
ngrok面板: 4040
```

---

## 🔄 工作流程

```
┌─────────────┐
│   本地电脑   │
│             │
│  ┌───────┐  │
│  │FastAPI│  │ (8000端口)
│  └───┬───┘  │
│      │      │
│  ┌───▼───┐  │
│  │ ngrok │  │ (创建隧道)
│  └───┬───┘  │
│      │      │
│      │ HTTPS
│      ▼      │
└─────────────┘
      │
      │ Internet
      │
┌─────▼──────┐
│ 企业微信服务器│
│            │
└────────────┘
```

---

## 📞 支持

如遇问题：
1. 查看文档清单中的详细文档
2. 查看日志输出
3. 检查ngrok面板
4. 联系技术支持

---

## ✅ 检查清单

### 安装阶段
- [ ] Python 3.12+ 已安装
- [ ] FastAPI依赖已安装
- [ ] ngrok已下载和安装
- [ ] ngrok已配置authtoken

### 启动阶段
- [ ] 运行环境检查脚本
- [ ] 启动FastAPI服务
- [ ] 启动ngrok隧道
- [ ] 复制ngrok HTTPS URL

### 配置阶段
- [ ] 登录企业微信管理后台
- [ ] 填写回调URL（使用ngrok URL）
- [ ] 填写Token
- [ ] 填写EncodingAESKey
- [ ] 点击验证按钮

### 验证阶段
- [ ] FastAPI服务收到请求
- [ ] 签名验证通过
- [ ] 企业微信显示"验证成功"

---

**创建时间**: 2026-01-15 02:45
**适用环境**: 本地开发环境
**工具栈**: Python + FastAPI + ngrok
