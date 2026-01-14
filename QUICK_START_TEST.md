# 简单快速测试指南 - 解决真机调试错误

## 🎯 目标：解决 "网络请求错误 undefined"

---

## ✅ 方法 1：在微信开发者工具中关闭域名校验（推荐，最快）

### 步骤：

1. **打开微信开发者工具**
2. **点击右上角的"详情"按钮**
3. **点击"本地设置"标签**
4. **勾选"不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书"**
5. **点击"编译"按钮**
6. **在小程序模拟器中测试上传图片功能**

### 完成！

⚠️ **注意**：这只是开发测试用的设置，正式发布前需要取消勾选！

---

## ✅ 方法 2：等待域名配置生效（如果刚配置好）

如果您刚刚在微信公众平台配置了域名（10 分钟内）：

1. ⏳ **等待 10 分钟**
2. **关闭微信开发者工具**
3. **重新打开微信开发者工具**
4. **点击"编译"**
5. **测试上传图片功能**

---

## ❌ 不要这样做

### ❌ 不要在 PowerShell 中执行 JavaScript 代码

**错误示例**：
```powershell
PS C:\> const apiUrl = 'https://tnho-fasteners.com';
const: The term 'const' is not recognized...
```

**原因**：PowerShell 不支持 JavaScript 语法。

---

### ❌ 不要在服务器终端执行 JavaScript 代码

**错误示例**：
```bash
[root@server ~]# const apiUrl = 'https://tnho-fasteners.com';
Command 'const' not found...
```

**原因**：服务器终端不支持 JavaScript 语法。

---

## 📍 代码应该在哪里写？

### JavaScript 代码 → 在微信开发者工具中编辑

**文件位置**：`C:\Users\12187\Desktop\tnho-miniprogram\app.js`

**编辑方式**：
1. 打开微信开发者工具
2. 在左侧文件列表中找到 `app.js`
3. 点击文件
4. 在编辑区域修改代码
5. 保存（Ctrl+S）

**示例代码**（在 `app.js` 中）：
```javascript
const apiUrl = 'https://tnho-fasteners.com';

App({
  onLaunch() {
    console.log('小程序启动');
  }
});
```

---

### Shell 命令 → 在服务器终端中执行

**执行方式**：
1. 打开 PowerShell 或 CMD
2. 连接到服务器（SSH）
3. 输入命令
4. 按 Enter

**示例命令**（在服务器终端中）：
```bash
systemctl status tnho-api
curl https://tnho-fasteners.com/health
```

---

## 🚀 现在就开始测试

### 步骤 1：打开微信开发者工具

```
开始菜单 → 微信开发者工具
```

### 步骤 2：打开项目

```
导入项目 → 选择：C:\Users\12187\Desktop\tnho-miniprogram
```

### 步骤 3：关闭域名校验

```
点击"详情" → "本地设置" → 勾选"不校验合法域名"
```

### 步骤 4：编译并测试

```
点击"编译" → 在模拟器中点击"上传图片"按钮
```

### 步骤 5：查看结果

```
观察控制台 Network 标签 → 查看是否成功
```

---

## 🔍 如果还有问题

### 检查 1：服务是否运行

**在哪里执行**：在服务器终端（SSH 连接）

```bash
systemctl status tnho-api
```

**预期结果**：`Active: active (running)`

---

### 检查 2：API 是否可以访问

**在哪里执行**：在服务器终端（SSH 连接）

```bash
curl https://tnho-fasteners.com/health
```

**预期结果**：`{"status":"ok"}`

---

### 检查 3：查看服务器日志

**在哪里执行**：在服务器终端（SSH 连接）

```bash
journalctl -u tnho-api -n 50
```

**预期结果**：没有大量错误信息

---

## 📋 快速检查清单

### 在微信开发者工具中：

- [ ] 已打开项目：`C:\Users\12187\Desktop\tnho-miniprogram`
- [ ] 已勾选"不校验合法域名"
- [ ] 已点击"编译"
- [ ] 模拟器显示正常
- [ ] 点击"上传图片"按钮
- [ ] 查看控制台 Network 标签

### 在服务器上：

- [ ] 服务正在运行：`systemctl status tnho-api`
- [ ] API 可以访问：`curl https://tnho-fasteners.com/health`
- [ ] 没有错误日志：`journalctl -u tnho-api -n 50`

---

## 🎉 预期结果

### 成功的标志：

1. ✅ 小程序模拟器正常显示
2. ✅ 点击"上传图片"可以选择图片
3. ✅ 控制台 Network 标签显示请求成功
4. ✅ 返回图片 URL
5. ✅ 图片预览显示

### 如果失败：

1. 🔴 控制台显示"网络请求错误"
2. 🔴 控制台显示"不在合法域名列表中"
3. 🔴 查看服务器日志：`journalctl -u tnho-api -f`

---

## 💡 记住这两个地方

### 🖥️ 微信开发者工具
- **用途**：编辑和运行小程序代码
- **编辑文件**：`.js`、`.wxml`、`.wxss`
- **位置**：本地电脑

### 💻 服务器终端
- **用途**：管理服务器和测试 API
- **执行命令**：`systemctl`、`curl`、`bash`
- **位置**：通过 SSH 连接

---

## 📞 需要帮助？

如果测试仍然失败，请提供：

1. **微信开发者工具的控制台错误信息**（截图）
2. **服务器状态**：
   ```bash
   systemctl status tnho-api
   curl https://tnho-fasteners.com/health
   ```
3. **是否勾选了"不校验合法域名"**

---

**创建时间**：2026-01-14
**最后更新**：2026-01-14
