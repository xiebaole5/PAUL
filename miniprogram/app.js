// app.js
App({
  globalData: {
    // 小程序版本
    version: '1.1.2',

    // 后端 API 地址配置
    // 注意：微信小程序要求使用HTTPS，且域名需要完成ICP备案
    // 当前配置：使用HTTP + IP地址（仅用于开发测试，生产环境必须使用HTTPS + 备案域名）
    // TODO: 完成域名备案和HTTPS证书配置后，修改为: apiBaseUrl: 'https://tnho-fasteners.com'
    apiBaseUrl: 'http://47.110.72.148'  // 通过Nginx 80端口反向代理到后端8080端口
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
