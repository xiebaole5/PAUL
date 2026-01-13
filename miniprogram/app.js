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
    // 开发环境（推荐）：
    // - 使用HTTP地址：http://47.110.72.148
    // - 优势：无需SSL证书，开发工具可忽略域名校验
    // - 适用场景：开发调试、真机预览
    //
    // 生产环境：
    // - 使用HTTPS地址：https://tnho-fasteners.com
    // - 前置条件：
    //   1. 需要申请Let's Encrypt正式SSL证书（非自签名）
    //   2. 在小程序后台配置服务器域名白名单
    //   3. Cloudflare SSL/TLS模式设为 Full
    // - 适用场景：正式上线
    //
    // ⚠️ 重要提示：
    // 1. 自签名证书会导致小程序无法上传图片（网络错误）
    // 2. 生产环境必须使用正式SSL证书（Let's Encrypt等）
    // 3. 开发阶段强烈建议使用HTTP地址
    //
    // 开发环境配置（推荐）：
    apiUrl: 'http://47.110.72.148',

    // 生产环境配置（正式上线时使用）：
    // apiUrl: 'https://tnho-fasteners.com',
    // ========================================
  }
})
