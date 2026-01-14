// app.js
App({
  onLaunch() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo
    this.globalData.isDevTool = systemInfo.platform === 'devtools'

    console.log('运行平台:', systemInfo.platform)
    console.log('使用API地址:', this.globalData.apiUrl)
  },

  globalData: {
    systemInfo: null,
    isDevTool: false,
    // 🔧 开发环境：使用服务器 IP + 端口（绕过 Cloudflare 和阿里云备案检查）
    // ⚠️ 注意：这是临时方案，仅用于开发测试
    // ⚠️ 正式发布前必须完成 ICP 备案并切换回域名
    apiUrl: 'http://47.110.72.148:9000',

    // 生产环境配置（ICP 备案完成后使用）：
    // apiUrl: 'https://tnho-fasteners.com',
  }
})
