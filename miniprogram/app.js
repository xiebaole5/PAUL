// app.js
App({
  onLaunch() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo

    // 自动检测运行环境
    // 开发工具 -> 使用HTTP开发地址
    // 真机预览 -> 根据配置选择
    const isDevTool = systemInfo.platform === 'devtools'
    this.globalData.isDevTool = isDevTool

    console.log('运行平台:', systemInfo.platform)
    console.log('使用API地址:', this.globalData.apiUrl)
  },

  globalData: {
    systemInfo: null,
    isDevTool: false,
    // ========================================
    // 🔧 API 地址配置（请根据实际情况修改）
    // ========================================
    //
    // 生产环境（正式上线）：
    // - 使用HTTPS地址：https://tnho-fasteners.com
    // - 已配置Let's Encrypt正式SSL证书
    // - 已在小程序后台配置合法域名
    // - 适用场景：正式上线
    //
    // 开发环境（备用）：
    // - 使用HTTP地址：http://47.110.72.148
    // - 无需SSL证书，开发工具可忽略域名校验
    // - 适用场景：开发调试（遇到HTTPS问题时使用）
    //
    // ⚠️ 重要提示：
    // 1. 正式上线必须使用HTTPS地址
    // 2. 小程序需要配置合法域名白名单
    // 3. 开发工具中需要关闭域名校验（如果使用HTTP）
    //
    // 🔧 开发环境配置（使用 IP 地址绕过 Cloudflare 和阿里云备案检查）
    // ⚠️ 注意：这是临时方案，仅用于开发测试
    // ⚠️ 正式发布前必须完成 ICP 备案并切换回域名
    apiUrl: 'https://47.110.72.148',

    // 生产环境配置（ICP 备案完成后使用）：
    // apiUrl: 'https://tnho-fasteners.com',
    // ========================================
  }
})
