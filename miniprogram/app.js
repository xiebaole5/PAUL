// app.js
App({
  onLaunch() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo
  },

  globalData: {
    systemInfo: null,
    // API 地址配置
    // 注意：小程序需要配置合法域名的服务器
    // 1. 生产环境：https://tnho-fasteners.com（需要在小程序后台配置合法域名）
    // 2. 开发环境：http://47.110.72.148（开发工具可忽略域名校验）
    // 3. 如果遇到证书问题，请在开发工具中关闭域名校验
    apiUrl: 'https://tnho-fasteners.com'
  }
})
