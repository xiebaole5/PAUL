// pages/index/index.js
Page({
  data: {
    // 版本号
    version: '',

    // 步骤：0-输入信息，1-查看脚本，2-选择图片，3-生成视频，4-完成
    step: 0,

    // 表单数据
    formData: {
      productName: '',
      usageScenario: '',
      themeDirection: '',
      productImageUrl: ''
    },

    // 生成的脚本
    script: '',

    // 生成的首尾帧图片
    firstFrames: [],  // 首帧图片列表（2张）
    lastFrames: [],   // 尾帧图片列表（2张）

    // 用户选择的图片
    selectedFirstFrame: '',
    selectedLastFrame: '',

    // 生成的视频
    videoUrl: '',

    // 加载状态
    loading: false,
    loadingText: '',

    // 错误信息
    error: ''
  },

  onLoad() {
    // 获取版本号
    const app = getApp()
    this.setData({
      version: app.globalData.version
    })
  },

  // 上传产品图片
  chooseImage() {
    console.log('===== chooseImage 函数被调用 =====')

    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        console.log('===== chooseImage success 回调 =====')
        console.log('res:', res)
        console.log('tempFilePaths:', res.tempFilePaths)

        const tempFilePaths = res.tempFilePaths
        if (tempFilePaths && tempFilePaths.length > 0) {
          console.log('即将调用 uploadImage，文件路径:', tempFilePaths[0])
          this.uploadImage(tempFilePaths[0])
        } else {
          console.error('tempFilePaths 为空！')
        }
      },
      fail: (err) => {
        console.error('chooseImage 失败:', err)
      }
    })
  },

  // 上传图片到服务器
  uploadImage(filePath) {
    console.log('===== uploadImage 函数被调用 =====')
    console.log('filePath:', filePath)

    wx.showLoading({
      title: '上传中...'
    })

    const app = getApp()
    const token = wx.getStorageSync('token') || ''
    const uploadUrl = `${app.globalData.apiBaseUrl}/api/upload-image`

    console.log('上传地址:', uploadUrl)
    console.log('文件路径:', filePath)

    wx.uploadFile({
      url: uploadUrl,
      filePath: filePath,
      name: 'file',
      header: {
        'Authorization': token
      },
      success: (res) => {
        wx.hideLoading()
        console.log('上传响应:', res)

        const data = JSON.parse(res.data)
        console.log('上传数据:', data)

        if (data.code === 0) {
          this.setData({
            'formData.productImageUrl': data.data.image_url
          })
          wx.showToast({
            title: '上传成功',
            icon: 'success'
          })
        } else {
          wx.showToast({
            title: data.message || '上传失败',
            icon: 'error'
          })
        }
      },
      fail: (err) => {
        wx.hideLoading()
        console.error('上传失败:', err)
        console.error('错误信息:', JSON.stringify(err))

        wx.showModal({
          title: '上传失败',
          content: `错误: ${err.errMsg}\n\n请确保：\n1. 后端服务已启动\n2. 已勾选"不校验合法域名"`,
          showCancel: false
        })
      }
    })
  },

  // 输入框变化
  onInputChange(e) {
    const field = e.currentTarget.dataset.field
    this.setData({
      [`formData.${field}`]: e.detail.value
    })
  },

  // 第一步：生成脚本
  generateScript() {
    const { productName, usageScenario, themeDirection, productImageUrl } = this.data.formData

    // 验证表单
    if (!productName || !usageScenario || !themeDirection) {
      wx.showToast({
        title: '请填写完整信息',
        icon: 'none'
      })
      return
    }

    if (!productImageUrl) {
      wx.showToast({
        title: '请上传产品图片',
        icon: 'none'
      })
      return
    }

    this.setData({
      loading: true,
      loadingText: '正在生成脚本...'
    })

    const app = getApp()

    wx.request({
      url: `${app.globalData.apiBaseUrl}/api/generate-script`,
      method: 'POST',
      data: {
        product_name: productName,
        product_image_url: productImageUrl,
        usage_scenario: usageScenario,
        theme_direction: themeDirection
      },
      success: (res) => {
        if (res.data.code === 0) {
          this.setData({
            script: res.data.data.script,
            step: 1
          })
          wx.showToast({
            title: '脚本生成成功',
            icon: 'success'
          })
        } else {
          this.setData({
            error: res.data.message || '脚本生成失败'
          })
          wx.showToast({
            title: res.data.message || '脚本生成失败',
            icon: 'error'
          })
        }
      },
      fail: (err) => {
        this.setData({
          error: '网络请求失败'
        })
        wx.showToast({
          title: '网络请求失败',
          icon: 'error'
        })
        console.error('请求失败:', err)
      },
      complete: () => {
        this.setData({
          loading: false
        })
      }
    })
  },

  // 确认脚本，继续生成图片
  confirmScript() {
    this.setData({
      loading: true,
      loadingText: '正在生成图片...'
    })

    const app = getApp()

    wx.request({
      url: `${app.globalData.apiBaseUrl}/api/generate-frames`,
      method: 'POST',
      data: {
        script: this.data.script,
        product_name: this.data.formData.productName,
        product_image_url: this.data.formData.productImageUrl
      },
      success: (res) => {
        if (res.data.code === 0) {
          this.setData({
            firstFrames: res.data.data.first_frames,
            lastFrames: res.data.data.last_frames,
            step: 2
          })
          wx.showToast({
            title: '图片生成成功',
            icon: 'success'
          })
        } else {
          this.setData({
            error: res.data.message || '图片生成失败'
          })
          wx.showToast({
            title: res.data.message || '图片生成失败',
            icon: 'error'
          })
        }
      },
      fail: (err) => {
        this.setData({
          error: '网络请求失败'
        })
        wx.showToast({
          title: '网络请求失败',
          icon: 'error'
        })
        console.error('请求失败:', err)
      },
      complete: () => {
        this.setData({
          loading: false
        })
      }
    })
  },

  // 选择首帧图片
  selectFirstFrame(e) {
    const url = e.currentTarget.dataset.url
    this.setData({
      selectedFirstFrame: url
    })
  },

  // 选择尾帧图片
  selectLastFrame(e) {
    const url = e.currentTarget.dataset.url
    this.setData({
      selectedLastFrame: url
    })
  },

  // 确认图片，开始生成视频
  confirmFrames() {
    if (!this.data.selectedFirstFrame || !this.data.selectedLastFrame) {
      wx.showToast({
        title: '请选择首尾帧图片',
        icon: 'none'
      })
      return
    }

    this.setData({
      loading: true,
      loadingText: '正在生成视频，请稍候...（约 3-5 分钟）'
    })

    const app = getApp()

    wx.request({
      url: `${app.globalData.apiBaseUrl}/api/generate-video`,
      method: 'POST',
      data: {
        script: this.data.script,
        product_name: this.data.formData.productName,
        product_image_url: this.data.formData.productImageUrl,
        selected_first_frame: this.data.selectedFirstFrame,
        selected_last_frame: this.data.selectedLastFrame
      },
      success: (res) => {
        if (res.data.code === 0) {
          this.setData({
            videoUrl: res.data.data.video_url,
            step: 3
          })
          wx.showToast({
            title: '视频生成成功',
            icon: 'success'
          })
        } else {
          this.setData({
            error: res.data.message || '视频生成失败'
          })
          wx.showToast({
            title: res.data.message || '视频生成失败',
            icon: 'error'
          })
        }
      },
      fail: (err) => {
        this.setData({
          error: '网络请求失败'
        })
        wx.showToast({
          title: '网络请求失败',
          icon: 'error'
        })
        console.error('请求失败:', err)
      },
      complete: () => {
        this.setData({
          loading: false
        })
      }
    })
  },

  // 重新开始
  reset() {
    this.setData({
      step: 0,
      formData: {
        productName: '',
        usageScenario: '',
        themeDirection: '',
        productImageUrl: ''
      },
      script: '',
      firstFrames: [],
      lastFrames: [],
      selectedFirstFrame: '',
      selectedLastFrame: '',
      videoUrl: '',
      error: ''
    })
  },

  // 返回上一步
  goBack() {
    if (this.data.step > 0) {
      this.setData({
        step: this.data.step - 1
      })
    }
  },

  // 处理视频分享事件
  onShareVideo() {
    wx.showToast({
      title: '分享功能',
      icon: 'none'
    })
  },

  // 页面分享配置
  onShareAppMessage() {
    return {
      title: '天虹紧固件视频生成',
      path: '/pages/index/index',
      imageUrl: ''
    }
  },

  // 退出登录
  handleLogout() {
    wx.showModal({
      title: '提示',
      content: '确定要退出登录吗？',
      success: (res) => {
        if (res.confirm) {
          const app = getApp()
          app.logout()
        }
      }
    })
  }
})
