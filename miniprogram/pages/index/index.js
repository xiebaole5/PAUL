// index.js
const app = getApp()

Page({
  data: {
    productName: '',
    theme: '品质保证',
    themes: ['品质保证', '技术创新', '工业应用', '品牌形象'],
    duration: 20,
    durations: [5, 10, 15, 20, 25, 30],
    generateType: 'video',
    scenario: '',
    productImageUrl: '',
    loading: false
  },

  onLoad(options) {
    // 页面加载
  },

  // 产品名称输入
  onProductNameInput(e) {
    this.setData({
      productName: e.detail.value
    })
  },

  // 主题选择
  onThemeSelect(e) {
    this.setData({
      theme: e.currentTarget.dataset.theme
    })
  },

  // 时长选择
  onDurationSelect(e) {
    this.setData({
      duration: e.currentTarget.dataset.duration
    })
  },

  // 生成类型选择
  onTypeSelect(e) {
    this.setData({
      generateType: e.currentTarget.dataset.type
    })
  },

  // 场景描述输入
  onScenarioInput(e) {
    this.setData({
      scenario: e.detail.value
    })
  },

  // 选择图片
  chooseImage() {
    const that = this
    wx.chooseMedia({
      count: 1,
      mediaType: ['image'],
      sourceType: ['album', 'camera'],
      sizeType: ['compressed'],
      success(res) {
        const tempFilePath = res.tempFiles[0].tempFilePath

        // 检查文件大小（5MB = 5 * 1024 * 1024）
        wx.getFileInfo({
          filePath: tempFilePath,
          success(fileInfo) {
            if (fileInfo.size > 5 * 1024 * 1024) {
              wx.showToast({
                title: '图片大小不能超过 5MB',
                icon: 'none'
              })
              return
            }

            // 上传图片
            that.uploadImage(tempFilePath)
          },
          fail() {
            wx.showToast({
              title: '获取文件信息失败',
              icon: 'none'
            })
          }
        })
      },
      fail(err) {
        console.error('选择图片失败', err)
        wx.showToast({
          title: '选择图片失败',
          icon: 'none'
        })
      }
    })
  },

  // 上传图片
  uploadImage(filePath) {
    const that = this
    wx.showLoading({
      title: '上传中...',
      mask: true
    })

    wx.uploadFile({
      url: `${app.globalData.apiUrl}/api/upload-image`,
      filePath: filePath,
      name: 'file',
      success(res) {
        wx.hideLoading()
        try {
          const data = JSON.parse(res.data)
          if (data.success) {
            that.setData({
              productImageUrl: data.image_url
            })
            wx.showToast({
              title: '上传成功',
              icon: 'success'
            })
          } else {
            wx.showToast({
              title: data.message || '上传失败',
              icon: 'none'
            })
          }
        } catch (err) {
          console.error('解析响应失败', err)
          wx.showToast({
            title: '上传失败',
            icon: 'none'
          })
        }
      },
      fail(err) {
        wx.hideLoading()
        console.error('上传失败', err)
        wx.showToast({
          title: '网络错误，上传失败',
          icon: 'none'
        })
      }
    })
  },

  // 删除图片
  removeImage() {
    this.setData({
      productImageUrl: ''
    })
  },

  // 生成视频
  generateVideo() {
    // 验证必填项
    if (!this.data.productName) {
      wx.showToast({
        title: '请输入产品名称',
        icon: 'none'
      })
      return
    }

    const that = this
    this.setData({ loading: true })

    const requestData = {
      product_name: this.data.productName,
      theme: this.data.theme,
      duration: this.data.duration,
      type: this.data.generateType
    }

    // 添加可选参数
    if (this.data.scenario) {
      requestData.scenario = this.data.scenario
    }
    if (this.data.productImageUrl) {
      requestData.product_image_url = this.data.productImageUrl
    }

    // 根据生成类型设置不同的超时时间
    const timeout = this.data.generateType === 'video' ? 5000 : 120000 // 视频异步5秒，脚本同步120秒

    wx.request({
      url: `${app.globalData.apiUrl}/api/generate-video`,
      method: 'POST',
      data: requestData,
      header: {
        'content-type': 'application/json'
      },
      timeout: timeout,
      success(res) {
        that.setData({ loading: false })

        if (res.data.success) {
          const type = res.data.type || that.data.generateType

          // 脚本类型仍然同步处理
          if (type === 'script' && res.data.script_content) {
            // 脚本生成成功，跳转到结果页
            wx.navigateTo({
              url: `/pages/result/result?type=script&scriptContent=${encodeURIComponent(res.data.script_content)}`
            })
            return
          }

          // 视频类型需要轮询进度
          if (type === 'video' && res.data.task_id) {
            that.pollProgress(res.data.task_id)
          } else {
            wx.showToast({
              title: res.data.message || '生成失败',
              icon: 'none'
            })
          }
        } else {
          wx.showToast({
            title: res.data.message || '生成失败',
            icon: 'none'
          })
        }
      },
      fail(err) {
        that.setData({ loading: false })
        console.error('生成失败', err)

        // 更友好的错误提示
        let errorMessage = '网络错误，生成失败'
        if (err.errMsg && err.errMsg.includes('timeout')) {
          errorMessage = this.data.generateType === 'script'
            ? '生成超时，请稍后重试或减少时长'
            : '请求超时，请检查网络连接'
        } else if (err.errMsg && err.errMsg.includes('fail')) {
          errorMessage = '服务器连接失败，请检查网络或稍后重试'
        }

        wx.showToast({
          title: errorMessage,
          icon: 'none',
          duration: 3000
        })
      }
    })
  },

  // 轮询任务进度
  pollProgress(taskId) {
    const that = this
    let pollingCount = 0
    const maxPollingCount = 180 // 最多轮询3分钟（2秒一次）

    wx.showLoading({
      title: '生成中 0%',
      mask: true
    })

    const poll = () => {
      pollingCount++

      wx.request({
        url: `${app.globalData.apiUrl}/api/progress/${taskId}`,
        method: 'GET',
        timeout: 5000,
        success(res) {
          if (res.data.success && res.data.progress !== undefined) {
            const progress = res.data.progress
            const status = res.data.status

            // 更新进度提示
            wx.showLoading({
              title: `${res.data.message || `生成中 ${progress}%`}`,
              mask: true
            })

            // 检查是否完成
            if (status === 'completed') {
              wx.hideLoading()

              // 准备跳转参数
              const params = {
                type: 'video',
                videoUrl: res.data.merged_video_url || (res.data.video_urls && res.data.video_urls[0]),
                mainVideo: res.data.merged_video_url || (res.data.video_urls && res.data.video_urls[0])
              }

              // 如果有多段视频，添加分段信息
              if (res.data.video_urls && res.data.video_urls.length > 1) {
                params.videoUrls = JSON.stringify(res.data.video_urls)
                params.mergedVideoUrl = res.data.merged_video_url || ''
              }

              // 将参数转换为查询字符串
              const queryString = Object.keys(params)
                .map(key => `${key}=${encodeURIComponent(params[key])}`)
                .join('&')

              // 跳转到结果页
              wx.navigateTo({
                url: `/pages/result/result?${queryString}`
              })

            } else if (status === 'failed') {
              wx.hideLoading()
              wx.showToast({
                title: res.data.error_message || '生成失败',
                icon: 'none',
                duration: 3000
              })
            } else if (pollingCount < maxPollingCount) {
              // 继续轮询
              setTimeout(poll, 2000) // 2秒后再次查询
            } else {
              // 超时
              wx.hideLoading()
              wx.showToast({
                title: '生成超时，请稍后查看',
                icon: 'none'
              })
            }
          } else {
            // 响应失败
            wx.hideLoading()
            wx.showToast({
              title: res.data.message || '查询进度失败',
              icon: 'none'
            })
          }
        },
        fail(err) {
          console.error('查询进度失败', err)
          if (pollingCount < maxPollingCount) {
            // 继续轮询
            setTimeout(poll, 2000)
          } else {
            wx.hideLoading()
            wx.showToast({
              title: '网络错误，无法查询进度',
              icon: 'none'
            })
          }
        }
      })
    }

    // 开始轮询
    poll()
  }
})
