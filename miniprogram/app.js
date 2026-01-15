// app.js
App({
  globalData: {
    // 后端 API 地址 - 部署后需要修改为实际的服务器地址
    // 本地测试: http://localhost:8000
    // 生产环境: https://your-domain.com
    apiBaseUrl: 'http://localhost:8000'
  },

  onLaunch() {
    console.log('天虹紧固件小程序启动')
  }
})
