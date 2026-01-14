// 小程序配置修复文件
// 用途：修复小程序 API 地址配置，适配开发环境

// 使用方法：
// 1. 打开微信开发者工具
// 2. 打开 miniprogram/app.js
// 3. 复制以下内容替换原有的 globalData 配置

// app.js 修复内容
// =============================================

App({
  onLaunch() {
    // 获取系统信息
    const systemInfo = wx.getSystemInfoSync()
    this.globalData.systemInfo = systemInfo
    this.globalData.isDevTool = systemInfo.platform === 'devtools'

    console.log('==========================================')
    console.log('天虹紧固件小程序启动')
    console.log('==========================================')
    console.log('运行平台:', systemInfo.platform)
    console.log('是否开发工具:', this.globalData.isDevTool)
    console.log('使用API地址:', this.globalData.apiUrl)
    console.log('==========================================')

    // 测试服务器连接
    this.testServerConnection()
  },

  // 测试服务器连接
  testServerConnection() {
    const apiUrl = this.globalData.apiUrl
    const healthUrl = `${apiUrl}/health`

    console.log('测试服务器连接:', healthUrl)

    wx.request({
      url: healthUrl,
      method: 'GET',
      timeout: 10000,
      success: (res) => {
        console.log('✓ 服务器连接成功', res.data)
        wx.showToast({
          title: '服务器连接成功',
          icon: 'success',
          duration: 2000
        })
      },
      fail: (err) => {
        console.error('✗ 服务器连接失败', err)
        wx.showModal({
          title: '服务器连接失败',
          content: `无法连接到服务器: ${apiUrl}\n\n请检查网络设置或联系技术支持`,
          showCancel: false
        })
      }
    })
  },

  globalData: {
    systemInfo: null,
    isDevTool: false,

    // ============================================================
    // 🔧 开发环境配置（当前使用）
    // ============================================================
    // 说明：
    // 1. 使用 HTTP 协议访问 IP 地址
    // 2. 绕过 Cloudflare CDN 和阿里云 ICP 备案检查
    // 3. 适用于开发测试阶段
    // ============================================================
    apiUrl: 'http://47.110.72.148',

    // ============================================================
    // 🚀 生产环境配置（ICP 备案完成后使用）
    // ============================================================
    // 说明：
    // 1. 使用 HTTPS 协议访问域名
    // 2. 需要完成 ICP 备案
    // 3. 适用于正式发布
    // ============================================================
    // apiUrl: 'https://tnho-fasteners.com',

    // ============================================================
    // ⚠️ 注意事项
    // ============================================================
    // 1. 开发环境：
    //    - 使用 IP 地址访问
    //    - 使用 HTTP 协议
    //    - 无需 ICP 备案
    //    - 适用于开发和测试
    //
    // 2. 生产环境：
    //    - 使用域名访问
    //    - 使用 HTTPS 协议
    //    - 必须完成 ICP 备案
    //    - 适用于正式发布
    //
    // 3. 切换环境：
    //    - 注释掉当前使用的 apiUrl
    //    - 取消注释目标环境的 apiUrl
    //    - 保存文件后重新编译小程序
    // ============================================================
  }
})

// =============================================
// 快速切换命令（注释说明）
// =============================================
//
// 切换到开发环境：
//   apiUrl: 'http://47.110.72.148',
//   // apiUrl: 'https://tnho-fasteners.com',
//
// 切换到生产环境：
//   // apiUrl: 'http://47.110.72.148',
//   apiUrl: 'https://tnho-fasteners.com',
//
// =============================================

// =============================================
// pages/index/index.js 修复内容
// =============================================

// 在 pages/index/index.js 中，确保使用正确的 API 地址：

Page({
  data: {
    // ... 其他数据
  },

  onLoad() {
    const app = getApp()
    console.log('API地址:', app.globalData.apiUrl)

    // 加载主题列表
    this.loadThemes()
  },

  // ... 其他方法

  loadThemes() {
    const app = getApp()
    const apiUrl = app.globalData.apiUrl

    wx.request({
      url: `${apiUrl}/api/themes`,
      method: 'GET',
      timeout: 10000,  // 10 秒超时
      success: (res) => {
        console.log('主题列表:', res.data)
        // ... 处理数据
      },
      fail: (err) => {
        console.error('加载主题失败:', err)
        wx.showToast({
          title: '加载失败',
          icon: 'none'
        })
      }
    })
  },

  uploadImage() {
    const app = getApp()
    const apiUrl = app.globalData.apiUrl

    wx.chooseImage({
      count: 1,
      sizeType: ['compressed'],
      sourceType: ['album', 'camera'],
      success: (res) => {
        const tempFilePath = res.tempFilePaths[0]

        wx.uploadFile({
          url: `${apiUrl}/api/upload-image`,
          filePath: tempFilePath,
          name: 'file',
          timeout: 30000,  // 30 秒超时
          success: (uploadRes) => {
            const data = JSON.parse(uploadRes.data)
            console.log('图片上传成功:', data)
            // ... 处理上传结果
          },
          fail: (err) => {
            console.error('图片上传失败:', err)
            wx.showToast({
              title: '上传失败',
              icon: 'none'
            })
          }
        })
      }
    })
  },

  generateVideo(formData) {
    const app = getApp()
    const apiUrl = app.globalData.apiUrl

    wx.request({
      url: `${apiUrl}/api/generate-video`,
      method: 'POST',
      data: formData,
      timeout: 5000,  // 5 秒超时（异步任务）
      success: (res) => {
        console.log('视频生成任务已创建:', res.data)
        const taskId = res.data.task_id

        // 开始轮询进度
        this.pollProgress(taskId)
      },
      fail: (err) => {
        console.error('创建视频生成任务失败:', err)
        wx.showToast({
          title: '创建任务失败',
          icon: 'none'
        })
      }
    })
  },

  pollProgress(taskId) {
    const app = getApp()
    const apiUrl = app.globalData.apiUrl

    const maxAttempts = 90  // 90 * 2s = 3 分钟
    let attempts = 0

    const poll = () => {
      if (attempts >= maxAttempts) {
        wx.showToast({
          title: '任务超时',
          icon: 'none'
        })
        return
      }

      wx.request({
        url: `${apiUrl}/api/progress/${taskId}`,
        method: 'GET',
        timeout: 10000,
        success: (res) => {
          const progress = res.data
          console.log('任务进度:', progress)

          // 更新进度显示
          this.setData({
            progress: progress.progress,
            status: progress.status
          })

          if (progress.status === 'completed') {
            wx.showToast({
              title: '生成成功',
              icon: 'success'
            })
          } else if (progress.status === 'failed') {
            wx.showToast({
              title: `生成失败: ${progress.error}`,
              icon: 'none',
              duration: 3000
            })
          } else {
            // 继续轮询
            attempts++
            setTimeout(poll, 2000)
          }
        },
        fail: (err) => {
          console.error('查询进度失败:', err)
          attempts++
          setTimeout(poll, 2000)
        }
      })
    }

    poll()
  }
})

// =============================================
// 配置检查清单
// =============================================
//
// □ app.js 中 apiUrl 配置为 http://47.110.72.148
// □ pages/index/index.js 使用 getApp().globalData.apiUrl
// □ 请求超时时间设置合理（视频生成5秒，脚本生成120秒，图片上传30秒）
// □ 真机调试时如遇网络错误，在微信开发者工具中关闭域名校验
// □ 小程序后台配置合法域名（https://tnho-fasteners.com，生产环境）
//
// =============================================

// =============================================
// 常见问题解决
// =============================================
//
// Q1: 小程序提示 "不在以下 request 合法域名列表中"
// A1: 在微信开发者工具中，点击右上角详情 -> 本地设置 -> 勾选"不校验合法域名"
//
// Q2: 小程序提示 "request:fail timeout"
// A2: 检查网络连接，增加请求超时时间
//
// Q3: 小程序提示 "服务器连接失败"
// A3: 检查服务器是否运行，使用 curl 测试：curl http://47.110.72.148/health
//
// Q4: 图片上传失败
// A4: 检查服务器端 Nginx 配置 client_max_body_size 是否足够（10M）
//
// Q5: 视频生成失败
// A5: 检查火山方舟 API Key 是否正确，检查服务器端日志
//
// =============================================
