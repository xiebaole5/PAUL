# 天虹紧固件小程序 - 下载指南

## 📦 打包文件

已为您打包的文件：
- **文件名**: `tnho-video-miniprogram.tar.gz`
- **大小**: ~150KB
- **位置**: 服务器上的 `/workspace/tnho-video-miniprogram.tar.gz`

---

## 📥 下载方式

### 方式一：SCP 命令（最简单）

**Windows (PowerShell)**:
```powershell
scp username@server-ip:/workspace/tnho-video-miniprogram.tar.gz C:\Users\YourName\Downloads\
```

**Mac/Linux**:
```bash
scp username@server-ip:/workspace/tnho-video-miniprogram.tar.gz ~/Downloads/
```

替换：
- `username` - 服务器用户名
- `server-ip` - 服务器 IP 地址

---

### 方式二：SFTP 客户端（图形界面）

推荐工具：
- **FileZilla** (免费) - https://filezilla-project.org/
- **WinSCP** (Windows) - https://winscp.net/
- **Cyberduck** (Mac) - https://cyberduck.io/

步骤：
1. 下载并安装工具
2. 连接到服务器（输入 IP、用户名、密码）
3. 找到 `/workspace/tnho-video-miniprogram.tar.gz`
4. 右键下载到本地

---

### 方式三：在服务器上查看文件列表

文件内容：
```
projects/
├── MINIPROGRAM_README.md      # 部署文档
├── README.md
├── src/
│   ├── api/app.py             # 后端 API
│   ├── agents/agent.py        # Agent
│   └── tools/video_generation_tool.py
├── config/agent_llm_config.json
└── miniprogram/               # 小程序
    ├── app.json, app.js, app.wxss
    ├── project.config.json
    └── pages/index/
```

---

## 📦 解压文件

**Windows**: 使用 7-Zip 或 WinRAR 右键解压
**Mac/Linux**: `tar -xzf tnho-video-miniprogram.tar.gz`

---

## 🚀 快速开始

1. **阅读** `MINIPROGRAM_README.md`
2. **后端**: `uvicorn src.api.app:app --host 0.0.0.0 --port 8000`
3. **小程序**: 用微信开发者工具打开 `miniprogram` 目录

---

**需要帮助？请告诉我你使用的系统和遇到的问题！**
