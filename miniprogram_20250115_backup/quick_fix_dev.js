// 小程序开发环境快速修复配置
//
// 使用说明：
// 1. 将本文件中的代码复制到 miniprogram/app.js
// 2. 覆盖原来的配置
// 3. 刷新微信开发者工具
//
// 注意：此配置仅用于开发调试，正式发布前必须恢复为 HTTPS 地址

App({
  onLaunch() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo

    // 自动检测运行环境
    const isDevTool = systemInfo.platform === 'devtools'
    this.globalData.isDevTool = isDevTool

    console.log('运行平台:', systemInfo.platform)
    console.log('使用API地址:', this.globalData.apiUrl)
    console.log('⚠️ 警告：当前使用开发环境配置，正式发布前必须修改为 HTTPS 地址')
  },

  globalData: {
    systemInfo: null,
    isDevTool: false,

    // ========================================
    // 🔧 开发环境快速修复配置
    // ========================================
    //
    // 当前问题：HTTPS 使用自签名证书，小程序拒绝连接
    //
    // 解决方案：
    // 1. 在微信开发者工具中关闭域名校验（详见下方说明）
    // 2. 使用以下任一地址：
    //
    // 选项 A：HTTP 地址（推荐，开发调试）
    //    apiUrl: 'http://47.110.72.148',
    //
    // 选项 B：HTTPS 地址（需要在开发工具中关闭域名校验）
    //    apiUrl: 'https://tnho-fasteners.com',
    //
    // 选项 C：本地测试（如果服务在本地运行）
    //    apiUrl: 'http://localhost:8080',
    //
    // ========================================

    // 🎯 开发环境配置（使用 HTTP 地址，适合快速调试）
    apiUrl: 'http://47.110.72.148',

    // 备用配置（如果遇到网络问题，可以尝试使用）
    // apiUrl: 'https://47.110.72.148',  // 使用 HTTPS（需关闭域名校验）

    // ❌ 正式发布配置（暂时禁用，等待升级证书）
    // apiUrl: 'https://tnho-fasteners.com',
    // ========================================

    // 📋 重要提示：
    //
    // 1. 如何在微信开发者工具中关闭域名校验？
    //    - 点击右上角 "详情" 按钮
    //    - 选择 "本地设置" 标签
    //    - 勾选 "不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书"
    //    - 刷新小程序
    //
    // 2. 如何测试 API 是否可访问？
    //    - 在浏览器中访问：http://47.110.72.148/health
    //    - 应该看到：{"status":"ok"}
    //
    // 3. 如何恢复正式配置？
    //    - 按照以下步骤升级证书：
    //      1) 登录 Cloudflare 控制台
    //      2) 生成 Origin Certificate
    //      3) 上传证书到服务器
    //      4) 修改配置为：apiUrl: 'https://tnho-fasteners.com'
    //    - 详见：../docs/HTTPS_SETUP.md
    //
    // 4. 真机调试怎么办？
    //    - 真机调试必须使用受信任的 HTTPS 证书
    //    - 需要先升级为 Cloudflare Origin Certificate
    //    - 或使用 HTTPS + 关闭域名校验（不推荐）
    //
    // ========================================
  }
})
