# 微信小程序使用指南

## 📱 小程序概述

天虹紧固件视频生成小程序是一款基于 AI 的营销工具，帮助用户快速生成紧固件产品的宣传视频和营销脚本。

### 主要功能
- ✅ 视频生成：AI 自动生成 5-30 秒的宣传视频
- ✅ 脚本生成：生成营销视频脚本（含场景、文案、音效）
- ✅ 多主题选择：品质保证、技术创新、工业应用、品牌形象
- ✅ 时长定制：5/10/15/20/25/30 秒六种时长
- ✅ 一键分享：生成后可直接分享视频

---

## 🚀 快速开始

### 开发环境配置

#### 1. 下载微信开发者工具

访问 [微信开发者工具官网](https://developers.weixin.qq.com/miniprogram/dev/devtools/download.html)，下载并安装适合你操作系统的版本。

#### 2. 导入项目

1. 打开微信开发者工具
2. 选择「导入项目」
3. 项目目录：选择 `miniprogram` 文件夹
4. AppID：填写你的小程序 AppID（开发阶段可选择「测试号」）
5. 项目名称：`天虹视频生成器`

#### 3. 配置开发环境

在微信开发者工具中：
1. 点击右上角「详情」
2. 在「本地设置」中勾选：
   - ☑️ 不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书
3. 这样可以使用本地后端服务进行调试

#### 4. 修改后端 API 地址

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 开发环境：使用本地地址
    apiBaseUrl: 'http://localhost:8000'

    // 生产环境：使用实际部署地址
    // apiBaseUrl: 'https://your-domain.com'
  }
})
```

---

## 📁 项目结构

```
miniprogram/
├── app.js              # 小程序主入口
├── app.json            # 小程序全局配置
├── app.wxss            # 全局样式
├── project.config.json # 项目配置文件
├── pages/              # 页面目录
│   └── index/          # 首页
│       ├── index.js    # 页面逻辑
│       ├── index.json  # 页面配置
│       ├── index.wxml  # 页面结构
│       └── index.wxss  # 页面样式
└── sitemap.json        # 索引配置
```

---

## 🔧 配置说明

### 1. project.config.json

小程序项目配置文件，主要配置项：

```json
{
  "appid": "your_appid_here",        // 小程序 AppID（必须替换）
  "projectname": "tnho-video-generator",
  "description": "天虹紧固件视频生成小程序",

  // 编译配置
  "setting": {
    "urlCheck": true,              // 是否检查合法域名
    "es6": true,                   // 是否启用 ES6 转 ES5
    "postcss": true,               // 是否启用 PostCSS
    "minified": true               // 是否压缩代码
  },

  // 打包配置
  "packOptions": {
    "ignore": []                   // 打包时忽略的文件
  }
}
```

### 2. app.json

小程序全局配置，定义页面路径和窗口样式：

```json
{
  "pages": [
    "pages/index/index"
  ],
  "window": {
    "backgroundTextStyle": "light",
    "navigationBarBackgroundColor": "#1890ff",
    "navigationBarTitleText": "天虹视频生成",
    "navigationBarTextStyle": "white",
    "backgroundColor": "#f5f5f5"
  },
  "style": "v2",
  "sitemapLocation": "sitemap.json"
}
```

---

## 💻 开发调试

### 调试技巧

#### 1. 查看日志

在微信开发者工具中：
- 点击「调试器」打开调试面板
- 查看 Console 输出调试信息
- 查看 Network 监控网络请求

#### 2. 模拟数据

在 `miniprogram/pages/index/index.js` 的 `onLoad` 方法中，可以添加测试数据：

```javascript
onLoad(options) {
  // 测试数据
  this.setData({
    productName: '高强度螺栓',
    selectedTheme: '品质保证',
    selectedDuration: 20
  })
}
```

#### 3. 清除缓存

如果遇到数据缓存问题：
1. 点击工具栏「清缓存」
2. 选择「清除数据缓存」和「清除文件缓存」
3. 重新编译项目

---

## 🎨 自定义样式

### 修改主题颜色

编辑 `miniprogram/pages/index/index.wxss`，修改渐变色和主题色：

```css
/* 修改主色调 - 蓝色系 */
.header {
  background: linear-gradient(180deg, #f0f5ff 0%, #f5f5f5 100%);
}

.title {
  color: #1890ff;  /* 主色调 */
}

.submit-btn {
  background: linear-gradient(135deg, #1890ff 0%, #40a9ff 100%);
}

/* 修改激活状态颜色 */
.type-item.active {
  background: linear-gradient(135deg, #722ed1 0%, #9254de 100%);  /* 紫色 */
}

.theme-item.active {
  background: linear-gradient(135deg, #1890ff 0%, #40a9ff 100%);  /* 蓝色 */
}

.duration-item.active {
  background: linear-gradient(135deg, #52c41a 0%, #73d13d 100%);  /* 绿色 */
}
```

### 修改 Logo

在 `miniprogram/pages/index/index.wxml` 中：

```xml
<view class="logo">
  <text class="logo-text">TNHO</text>
</view>
```

可以替换为图片 Logo：

```xml
<image class="logo-image" src="/assets/logo.png" mode="aspectFit" />
```

并在 `index.wxss` 中添加样式：

```css
.logo-image {
  width: 120rpx;
  height: 120rpx;
}
```

---

## 📤 生产环境发布

### 1. 配置服务器域名

在 [微信公众平台](https://mp.weixin.qq.com/)：

1. 登录后台
2. 进入「开发」-「开发管理」-「开发设置」
3. 在「服务器域名」中添加：
   - request 合法域名：`https://your-domain.com`
   - uploadFile 合法域名：`https://your-domain.com`
   - downloadFile 合法域名：`https://your-domain.com`

### 2. 修改生产环境配置

编辑 `miniprogram/app.js`：

```javascript
App({
  globalData: {
    // 生产环境：使用实际域名
    apiBaseUrl: 'https://your-domain.com'
  }
})
```

编辑 `miniprogram/project.config.json`：

```json
{
  "appid": "your_real_appid_here",
  "setting": {
    "urlCheck": true  // 生产环境必须开启域名检查
  }
}
```

### 3. 上传代码

1. 在微信开发者工具中点击「上传」
2. 填写版本号（如：1.0.0）
3. 填写项目备注（如：首次发布）

### 4. 提交审核

1. 登录微信公众平台
2. 进入「版本管理」-「开发版本」
3. 选择刚上传的版本，点击「提交审核」
4. 填写审核信息：
   - 功能页面：选择「首页」
   - 类目：选择「工具」-「效率」
   - 服务类目：选择合适的类目

### 5. 发布

审核通过后：
1. 进入「版本管理」-「审核版本」
2. 点击「发布」

---

## 🔐 权限配置

### 需要的权限

小程序需要以下权限：

1. **网络请求权限**（自动获得）
   - 用于调用后端 API

2. **保存图片到相册权限**（可选）
   - 用于下载生成的视频

3. **分享权限**（自动获得）
   - 用于分享视频到微信

### 配置方法

在 `miniprogram/pages/index/index.json` 中配置：

```json
{
  "usingComponents": {},
  "permission": {
    "scope.writePhotosAlbum": {
      "desc": "需要保存视频到相册"
    }
  }
}
```

---

## 🐛 常见问题

### Q1: 提示「不在以下 request 合法域名列表中」

**原因**：开发环境未关闭域名检查

**解决方法**：
- 在微信开发者工具中，点击「详情」-「本地设置」
- 勾选「不校验合法域名、web-view、TLS 版本以及 HTTPS 证书」

### Q2: 网络请求失败

**检查清单**：
1. 后端服务是否已启动
2. `apiBaseUrl` 配置是否正确
3. 是否在同一个网络环境（本地调试时）
4. 防火墙是否阻止了请求

**解决方法**：
```bash
# 检查后端服务
curl http://localhost:8000/health

# 查看小程序日志
# 微信开发者工具 - 调试器 - Console
```

### Q3: 视频无法播放

**可能原因**：
- 视频 URL 无效
- 视频格式不支持
- 网络问题

**解决方法**：
- 确认视频 URL 可以在浏览器中访问
- 检查视频格式是否为 mp4
- 尝试重新生成视频

### Q4: 真机调试时无法连接

**解决方法**：
1. 确保手机和电脑在同一个 WiFi 网络
2. 使用电脑的局域网 IP 地址
3. 在 `miniprogram/app.js` 中配置：
   ```javascript
   apiBaseUrl: 'http://192.168.1.100:8000'  // 替换为实际 IP
   ```

---

## 📚 参考资料

- [微信小程序官方文档](https://developers.weixin.qq.com/miniprogram/dev/framework/)
- [微信开发者工具使用指南](https://developers.weixin.qq.com/miniprogram/dev/devtools/devtools.html)
- [小程序 API 文档](https://developers.weixin.qq.com/miniprogram/dev/api/)
- [小程序组件文档](https://developers.weixin.qq.com/miniprogram/dev/component/)

---

## 📞 技术支持

如有问题，请查看：
- [部署指南](../DEPLOYMENT_GUIDE.md)
- [后端 API 文档](../src/api/README.md)
- [Agent 配置说明](../config/agent_llm_config.json)

---

**祝开发顺利！🎉**
