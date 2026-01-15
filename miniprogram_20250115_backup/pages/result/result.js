// result.js
const app = getApp()

Page({
  data: {
    type: 'video',
    videoUrl: '',
    mainVideo: '',
    videoUrls: [],
    videoParts: [],
    mergedVideoUrl: '',
    scriptContent: '',
    showAllVideos: false
  },

  onLoad(options) {
    // 获取结果类型和内容
    const { type, videoUrl, mainVideo, videoUrls, videoParts, mergedVideoUrl, scriptContent } = options

    this.setData({
      type: type || 'video',
      videoUrl: videoUrl ? decodeURIComponent(videoUrl) : '',
      mainVideo: mainVideo ? decodeURIComponent(mainVideo) : '',
      scriptContent: scriptContent ? decodeURIComponent(scriptContent) : ''
    })

    // 解析多段视频信息
    if (videoUrls) {
      try {
        this.setData({
          videoUrls: JSON.parse(decodeURIComponent(videoUrls))
        })
      } catch (err) {
        console.error('解析视频列表失败', err)
      }
    }

    // 解析视频分段信息
    if (videoParts) {
      try {
        this.setData({
          videoParts: JSON.parse(decodeURIComponent(videoParts))
        })
      } catch (err) {
        console.error('解析视频分段信息失败', err)
      }
    }

    // 解析拼接后的视频URL
    if (mergedVideoUrl) {
      this.setData({
        mergedVideoUrl: decodeURIComponent(mergedVideoUrl)
      })
    }
  },

  // 下载视频
  downloadVideo() {
    const that = this
    if (!this.data.videoUrl) {
      wx.showToast({
        title: '视频地址无效',
        icon: 'none'
      })
      return
    }

    wx.showLoading({
      title: '下载中...',
      mask: true
    })

    wx.downloadFile({
      url: this.data.videoUrl,
      success(res) {
        wx.hideLoading()
        if (res.statusCode === 200) {
          wx.saveVideoToPhotosAlbum({
            filePath: res.tempFilePath,
            success() {
              wx.showToast({
                title: '已保存到相册',
                icon: 'success'
              })
            },
            fail(err) {
              console.error('保存失败', err)
              wx.showModal({
                title: '保存失败',
                content: '请检查相册权限设置',
                confirmText: '去设置',
                success(res) {
                  if (res.confirm) {
                    wx.openSetting()
                  }
                }
              })
            }
          })
        } else {
          wx.showToast({
            title: '下载失败',
            icon: 'none'
          })
        }
      },
      fail(err) {
        wx.hideLoading()
        console.error('下载失败', err)
        wx.showToast({
          title: '下载失败，请重试',
          icon: 'none'
        })
      }
    })
  },

  // 分享视频
  shareVideo() {
    if (!this.data.videoUrl) {
      wx.showToast({
        title: '视频地址无效',
        icon: 'none'
      })
      return
    }

    // 微信小程序只能分享给好友或群
    return {
      title: '天虹紧固件宣传视频',
      path: '/pages/index/index',
      imageUrl: '' // 可设置分享图片
    }
  },

  // 复制脚本
  copyScript() {
    if (!this.data.scriptContent) {
      wx.showToast({
        title: '脚本内容为空',
        icon: 'none'
      })
      return
    }

    wx.setClipboardData({
      data: this.data.scriptContent,
      success() {
        wx.showToast({
          title: '已复制到剪贴板',
          icon: 'success'
        })
      },
      fail(err) {
        console.error('复制失败', err)
        wx.showToast({
          title: '复制失败',
          icon: 'none'
        })
      }
    })
  },

  // 分享脚本
  shareScript() {
    return {
      title: '天虹紧固件宣传脚本',
      path: '/pages/index/index'
    }
  },

  // 返回首页
  backToHome() {
    wx.navigateBack({
      delta: 1
    })
  },

  // 切换显示所有视频
  toggleVideoDisplay() {
    this.setData({
      showAllVideos: !this.data.showAllVideos
    })
  },

  // 下载指定视频
  downloadSpecificVideo(e) {
    const index = e.currentTarget.dataset.index
    const videoUrl = e.currentTarget.dataset.url
    const that = this

    if (!videoUrl) {
      wx.showToast({
        title: '视频地址无效',
        icon: 'none'
      })
      return
    }

    wx.showLoading({
      title: '下载中...',
      mask: true
    })

    wx.downloadFile({
      url: videoUrl,
      success(res) {
        wx.hideLoading()
        if (res.statusCode === 200) {
          wx.saveVideoToPhotosAlbum({
            filePath: res.tempFilePath,
            success() {
              wx.showToast({
                title: '已保存到相册',
                icon: 'success'
              })
            },
            fail(err) {
              console.error('保存失败', err)
              wx.showModal({
                title: '保存失败',
                content: '请检查相册权限设置',
                confirmText: '去设置',
                success(res) {
                  if (res.confirm) {
                    wx.openSetting()
                  }
                }
              })
            }
          })
        } else {
          wx.showToast({
            title: '下载失败',
            icon: 'none'
          })
        }
      },
      fail(err) {
        wx.hideLoading()
        console.error('下载失败', err)
        wx.showToast({
          title: '下载失败，请重试',
          icon: 'none'
        })
      }
    })
  }
})
