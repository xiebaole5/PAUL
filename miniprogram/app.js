// app.js
App({
  globalData: {
    // 小程序版本
    version: '1.1.2',

    // 后端 API 地址
    // 开发环境: http://47.110.72.148
    // 生产环境: https://tnho-fasteners.com
    // 注意：开发时使用远程服务器地址，无需本地启动后端服务
    apiBaseUrl: 'http://47.110.72.148'
  },

  onLaunch() {
    console.log('天虹紧固件小程序启动')

    // 检查登录状态
    this.checkLogin()
  },

  // 检查登录状态
  checkLogin() {
    const isLoggedIn = wx.getStorageSync('isLoggedIn')

    if (!isLoggedIn) {
      // 未登录，跳转到登录页
      wx.reLaunch({
        url: '/pages/login/login'
      })
    }
  },

  // 登出
  logout() {
    // 清除登录状态
    wx.removeStorageSync('isLoggedIn')
    wx.removeStorageSync('loginTime')

    // 跳转到登录页
    wx.reLaunch({
      url: '/pages/login/login'
    })
  },

  // 检查是否已登录
  isLoggedIn() {
    return wx.getStorageSync('isLoggedIn') || false
  }
})
