# 代码执行位置指南 - 避免混淆

## 📌 重要提示

**JavaScript 代码**（如 `const apiUrl = '...'`、`wx.uploadFile({...})`）是小程序前端代码，应该在**微信开发者工具**中编写和运行，**不能在服务器终端执行**。

**Shell 命令**（如 `systemctl status tnho-api`、`curl`）是服务器管理命令，应该在**服务器终端**执行，**不能在小程序中运行**。

---

## 🔍 如何区分

### ✅ 应该在微信开发者工具中运行的代码

**特征**：
- 使用 `const`、`let`、`var` 定义变量
- 使用 `wx.` 开头的 API 调用
- 使用 `console.log()` 打印日志
- 使用箭头函数 `() => {}`
- 文件扩展名是 `.js`

**示例**：
```javascript
// app.js - 小程序配置文件
const apiUrl = 'https://tnho-fasteners.com';

App({
  onLaunch() {
    console.log('小程序启动');
  }
});
```

```javascript
// pages/index/index.js - 小程序页面逻辑
Page({
  data: {
    apiUrl: 'https://tnho-fasteners.com'
  },
  
  uploadImage() {
    wx.chooseImage({
      success: (res) => {
        const tempFilePath = res.tempFilePaths[0];
        
        wx.uploadFile({
          url: `${this.data.apiUrl}/api/upload-image`,
          filePath: tempFilePath,
          name: 'file',
          success: (res) => {
            console.log('上传成功', res);
          },
          fail: (err) => {
            console.error('上传失败', err);
          }
        });
      }
    });
  }
});
```

**执行位置**：
1. 打开微信开发者工具
2. 在项目目录中找到对应的 `.js` 文件
3. 修改代码
4. 保存文件
5. 点击 **编译** 按钮

---

### ✅ 应该在服务器终端执行的命令

**特征**：
- 使用 `systemctl`、`curl`、`ls`、`cd` 等命令
- 不使用 `const`、`let`、`var`
- 文件扩展名是 `.sh`（脚本文件）

**示例**：
```bash
# 检查服务状态
systemctl status tnho-api

# 测试 API 接口
curl https://tnho-fasteners.com/health

# 查看日志
journalctl -u tnho-api -n 50

# 进入目录
cd /root/PAUL

# 运行诊断脚本
bash diagnose_network_error.sh
```

**执行位置**：
1. 通过 SSH 连接到服务器
2. 在终端中输入命令
3. 按 Enter 键执行

---

## 🎯 当前问题解决方案

### 问题：真机调试网络请求错误

您应该按照以下步骤操作，**不是在服务器终端执行 JavaScript 代码**：

#### 第 1 步：在服务器上运行诊断

在服务器终端执行（正确）：

```bash
cd /root/PAUL
bash diagnose_network_error.sh
```

#### 第 2 步：在微信开发者工具中配置

在微信开发者工具中操作（正确）：

1. 打开微信开发者工具
2. 点击右上角 **详情** 按钮
3. 进入 **本地设置** 标签
4. ✅ 勾选 **不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书**
5. 点击 **编译** 按钮

#### 第 3 步：在小程序中测试

在微信开发者工具的模拟器中操作（正确）：

1. 点击小程序的 **上传图片** 按钮
2. 选择一张本地图片
3. 观察控制台的 Network 标签
4. 查看是否成功

---

## 📁 代码文件位置

### 小程序代码（在本地电脑）

**位置**：`C:\Users\12187\Desktop\tnho-miniprogram`

**重要文件**：
- `app.js` - 小程序配置
- `pages/index/index.js` - 页面逻辑
- `pages/index/index.wxml` - 页面结构
- `pages/index/index.wxss` - 页面样式

**编辑方式**：
1. 使用代码编辑器（如 VS Code）
2. 或者在微信开发者工具中直接编辑

---

### 服务器代码（在服务器上）

**位置**：`/root/PAUL`

**重要文件**：
- `app.py` - FastAPI 应用入口
- `src/api/app.py` - API 接口定义
- `src/agents/agent.py` - Agent 逻辑
- `.env` - 环境变量配置

**编辑方式**：
1. SSH 连接到服务器
2. 使用 `vi`、`nano` 等编辑器
3. 或者通过 Git 管理代码

---

## 🛠️ 常用操作对比

### 操作：检查 API 地址

| 操作类型 | 命令/代码 | 执行位置 |
|---------|----------|---------|
| 服务器端检查 | `curl https://tnho-fasteners.com/health` | 服务器终端 |
| 小程序端检查 | 打开小程序控制台 Network 标签 | 微信开发者工具 |

### 操作：上传图片

| 操作类型 | 命令/代码 | 执行位置 |
|---------|----------|---------|
| 服务器端测试 | `curl -X POST https://tnho-fasteners.com/api/upload-image -F "file=@/tmp/test.txt"` | 服务器终端 |
| 小程序端操作 | 在小程序中点击"上传图片"按钮 | 微信开发者工具/手机 |

### 操作：查看日志

| 操作类型 | 命令/代码 | 执行位置 |
|---------|----------|---------|
| 服务器端日志 | `journalctl -u tnho-api -f` | 服务器终端 |
| 小程序端日志 | 查看微信开发者工具 Console 标签 | 微信开发者工具 |

---

## 🚨 常见错误

### 错误 1：在服务器终端执行 JavaScript 代码

❌ **错误**：
```bash
[root@server ~]# const apiUrl = 'https://tnho-fasteners.com';
Command 'const' not found
```

✅ **正确**：
在微信开发者工具中打开 `app.js` 文件，修改代码：
```javascript
const apiUrl = 'https://tnho-fasteners.com';
```

---

### 错误 2：在小程序中执行 Shell 命令

❌ **错误**：
```javascript
wx.request({
  url: 'systemctl status tnho-api'  // 错误！不能在小程序中执行 Shell 命令
});
```

✅ **正确**：
在服务器终端执行：
```bash
systemctl status tnho-api
```

---

### 错误 3：混淆文件路径

❌ **错误**：
在服务器上找 `C:\Users\12187\Desktop\tnho-miniprogram`

✅ **正确**：
- 小程序代码在：`C:\Users\12187\Desktop\tnho-miniprogram`（本地电脑）
- 服务器代码在：`/root/PAUL`（服务器）

---

## 📋 快速参考表

| 代码类型 | 扩展名 | 执行位置 | 编辑器 |
|---------|-------|---------|--------|
| 小程序 JavaScript | `.js` | 微信开发者工具 | VS Code / 微信开发者工具 |
| 小程序模板 | `.wxml` | 微信开发者工具 | VS Code / 微信开发者工具 |
| 小程序样式 | `.wxss` | 微信开发者工具 | VS Code / 微信开发者工具 |
| 服务器 Python | `.py` | 服务器终端 | VS Code / vi / nano |
| Shell 脚本 | `.sh` | 服务器终端 | VS Code / vi / nano |
| 配置文件 | `.env`, `.json` | 服务器终端 | VS Code / vi / nano |

---

## 🎯 当前任务清单

### 在服务器上执行（使用终端）：

- [ ] 运行诊断脚本：`cd /root/PAUL && bash diagnose_network_error.sh`
- [ ] 检查服务状态：`systemctl status tnho-api`
- [ ] 测试 API 接口：`curl https://tnho-fasteners.com/health`
- [ ] 查看服务日志：`journalctl -u tnho-api -n 50`

### 在微信开发者工具中执行：

- [ ] 打开项目：`C:\Users\12187\Desktop\tnho-miniprogram`
- [ ] 点击 **详情** → **本地设置**
- [ ] 勾选 **不校验合法域名**
- [ ] 点击 **编译**
- [ ] 在模拟器中测试上传图片功能
- [ ] 查看控制台 Network 标签

---

## 📞 如果还有疑问

如果不确定代码应该在哪里执行：

1. **看代码特征**：
   - 有 `const`、`wx.` → 在微信开发者工具中运行
   - 有 `systemctl`、`curl` → 在服务器终端运行

2. **看文件位置**：
   - 在 `C:\Users\12187\Desktop\tnho-miniprogram` → 在本地编辑
   - 在 `/root/PAUL` → 在服务器上编辑

3. **看执行环境**：
   - 微信开发者工具的模拟器 → 小程序代码
   - 服务器 SSH 终端 → Shell 命令

---

**创建时间**：2026-01-14
**最后更新**：2026-01-14
