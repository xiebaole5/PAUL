// pages/login/login.js
Page({
  data: {
    username: '',
    password: '',
    showPassword: false,
    loading: false,
    version: ''
  },

  onLoad() {
    // 获取版本号
    const app = getApp()
    this.setData({
      version: app.globalData.version
    })
  },

  // 用户名输入
  onUsernameInput(e) {
    this.setData({
      username: e.detail.value
    })
  },

  // 密码输入
  onPasswordInput(e) {
    this.setData({
      password: e.detail.value
    })
  },

  // 切换密码显示/隐藏
  togglePassword() {
    this.setData({
      showPassword: !this.data.showPassword
    })
  },

  // 登录
  handleLogin() {
    const { username, password } = this.data

    // 验证输入
    if (!username || !password) {
      wx.showToast({
        title: '请输入用户名和密码',
        icon: 'none'
      })
      return
    }

    // 验证用户名和密码
    if (username === 'thjgj' && password === '8888') {
      this.setData({ loading: true })

      // 模拟登录延迟
      setTimeout(() => {
        // 保存登录状态
        wx.setStorageSync('isLoggedIn', true)
        wx.setStorageSync('loginTime', new Date().getTime())

        wx.showToast({
          title: '登录成功',
          icon: 'success'
        })

        // 跳转到首页
        setTimeout(() => {
          wx.switchTab({
            url: '/pages/index/index',
            fail: () => {
              wx.redirectTo({
                url: '/pages/index/index'
              })
            }
          })
        }, 1000)
      }, 500)
    } else {
      wx.showToast({
        title: '用户名或密码错误',
        icon: 'error',
        duration: 2000
      })

      // 清空密码
      this.setData({
        password: ''
      })
    }
  }
})
