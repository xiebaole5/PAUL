// components/video-result/video-result.js
Component({
  /**
   * 组件的属性列表
   */
  properties: {
    videoUrl: {
      type: String,
      value: ''
    }
  },

  /**
   * 组件的初始数据
   */
  data: {
    isPlaying: false
  },

  /**
   * 组件的生命周期
   */
  lifetimes: {
    attached() {
      console.log('video-result 组件已加载')
    }
  },

  /**
   * 组件的方法列表
   */
  methods: {
    // 播放视频
    onPlay() {
      this.setData({
        isPlaying: true
      })
    },

    // 暂停视频
    onPause() {
      this.setData({
        isPlaying: false
      })
    },

    // 分享视频
    onShareVideo() {
      this.triggerEvent('sharevideo')
    },

    // 重新制作
    onReset() {
      this.triggerEvent('reset')
    }
  }
})
