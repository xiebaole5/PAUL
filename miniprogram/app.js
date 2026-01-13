// app.js
App({
  onLaunch() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo
  },

  globalData: {
    systemInfo: null,
    // API 地址
    // 生产环境：https://tnho-fasteners.com
    // 开发环境（未配置HTTPS）：http://47.110.72.148
    apiUrl: 'https://tnho-fasteners.com'
  }
})
