# 天虹紧固件小程序 - 下载指南

## 📦 打包文件

已为您打包的文件：
- **文件名**: `tnho-video-miniprogram.tar.gz`
- **位置**: `/workspace/tnho-video-miniprogram.tar.gz`
- **大小**: 150KB
- **包含内容**:
  - 后端 API 服务
  - 微信小程序前端代码
  - 配置文件
  - 部署文档

---

## 📥 下载方式

### 方式一：使用 SCP 命令（推荐）

#### Windows 用户（使用 PowerShell 或 Git Bash）

```powershell
# 在本地 PowerShell 中执行
scp username@your-server-ip:/workspace/tnho-video-miniprogram.tar.gz C:\Users\YourName\Downloads\
```

#### Mac/Linux 用户

```bash
# 在本地终端中执行
scp username@your-server-ip:/workspace/tnho-video-miniprogram.tar.gz ~/Downloads/
```

**参数说明**:
- `username`: 你的服务器用户名
- `your-server-ip`: 你的服务器 IP 地址
- 最后的路径：你想保存到本地的路径

---

### 方式二：使用 SFTP 客户端（推荐新手）

推荐使用以下 SFTP 工具：

#### 1. FileZilla（免费）
1. 下载安装 [FileZilla](https://filezilla-project.org/)
2. 打开 FileZilla，输入服务器信息：
   - 主机：your-server-ip
   - 用户名：username
   - 密码：your-password
   - 端口：22
3. 连接后，导航到 `/workspace/`
4. 找到 `tnho-video-miniprogram.tar.gz`，右键下载到本地

#### 2. WinSCP（Windows）
1. 下载安装 [WinSCP](https://winscp.net/)
2. 连接到服务器
3. 找到文件并下载到本地

#### 3. Cyberduck（Mac）
1. 下载安装 [Cyberduck](https://cyberduck.io/)
2. 连接到服务器
3. 找到文件并下载到本地

---

### 方式三：使用 Git 克隆（如果你有 Git 仓库访问权限）

如果项目已经推送到 Git 仓库，可以直接克隆：

```bash
git clone your-git-repository-url
cd your-project
```

---

## 📦 解压文件

下载到本地后，如何解压：

### Windows
1. 下载 [7-Zip](https://www.7-zip.org/) 或 [WinRAR](https://www.win-rar.com/)
2. 右键点击 `tnho-video-miniprogram.tar.gz`
3. 选择"解压到..."

### Mac/Linux
```bash
cd ~/Downloads/
tar -xzf tnho-video-miniprogram.tar.gz
```

解压后会得到 `projects` 文件夹。

---

## 📂 项目结构说明

解压后，你会看到以下结构：

```
projects/
├── 📄 MINIPROGRAM_README.md      # 部署文档（必看！）
├── 📄 README.md
├── 📄 requirements.txt
├── src/
│   ├── api/                     # 后端 API
│   │   └── app.py
│   ├── agents/                  # Agent
│   │   └── agent.py
│   └── tools/                   # 工具
│       └── video_generation_tool.py
├── config/
│   └── agent_llm_config.json
└── miniprogram/                 # 小程序前端
    ├── app.json
    ├── app.js
    ├── app.wxss
    ├── project.config.json
    └── pages/
        └── index/
            ├── index.js
            ├── index.json
            ├── index.wxml
            └── index.wxss
```

---

## 🚀 快速开始

### 1. 部署后端

```bash
# 进入项目目录
cd projects

# 安装依赖
pip install -r requirements.txt

# 启动服务
uvicorn src.api.app:app --host 0.0.0.0 --port 8000
```

### 2. 运行小程序

1. 打开微信开发者工具
2. 点击"导入项目"
3. 选择 `projects/miniprogram` 目录
4. 填写 AppID（测试号或正式 AppID）
5. 点击"导入"

### 3. 修改 API 地址

编辑 `miniprogram/app.js`，修改 `apiBaseUrl`：

```javascript
app.globalData = {
  apiBaseUrl: 'http://your-server-ip:8000'  // 改为实际的后端地址
}
```

---

## ❓ 常见问题

### Q1: 我不知道服务器 IP 怎么办？
联系你的服务器管理员或云服务提供商，获取服务器 IP 地址。

### Q2: 我不知道用户名和密码怎么办？
- 如果是云服务器（阿里云、腾讯云等），登录云平台控制台查看
- 联系系统管理员

### Q3: 下载速度很慢怎么办？
- 确保网络连接稳定
- 尝试更换下载时间（避开高峰期）
- 考虑使用更快的 SFTP 客户端

### Q4: 下载后文件打不开怎么办？
- 确保下载完整（文件大小应为 150KB 左右）
- 使用 7-Zip、WinRAR 等工具解压
- 不要直接用记事本打开压缩文件

---

## 📞 需要帮助？

如果下载过程中遇到问题，请提供以下信息：
1. 使用的操作系统（Windows/Mac/Linux）
2. 使用哪种下载方式（SCP/SFTP/Git）
3. 遇到的具体错误信息

---

**祝使用愉快！**
