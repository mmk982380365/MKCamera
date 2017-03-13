//
//  MKCameraPreviewView.swift
//  MKCamera
//
//  Created by MaMingkun on 2017/3/13.
//  Copyright © 2017年 MaMingkun. All rights reserved.
//

import UIKit
import AVFoundation

class MKCameraPreviewView: UIView {
    
    
    /// 预览界面类型
    ///
    /// - photos: 照片
    /// - videos: 视频
    enum PreviewType {
        case photos, videos
    }
    
    /// 设定当前类型 根据类型控制显示
    var previewType: PreviewType = .photos {
        didSet{
            switch previewType {
            case .photos:
                imageView.alpha = 1.0
                videoView.alpha = 0.0
            case .videos:
                imageView.alpha = 0.0
                videoView.alpha = 1.0
            }
        }
    }
    
    /// 图片
    var imageView: UIImageView!
    
    /// 视频
    var videoView: UIView!
    
    /// 播放器
    var player: AVPlayer!
    
    /// 播放器显示layer
    var playerLayer: AVPlayerLayer!
    
    /// 当前播放对象
    var currentPlayerItem: AVPlayerItem!
    
    /// 当前图片
    var image: UIImage? {
        didSet{
            imageView.image = image
        }
    }
    
    /// 当前视频地址
    var videoPath: URL? {
        didSet{
            
            if videoPath != nil {
                
                let item = AVPlayerItem(url: videoPath!)
                player.pause()
                player.replaceCurrentItem(with: item)
                player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
                player.play()
                currentPlayerItem = item
            }
            
        }
    }
    
    /// 重拍按钮
    var cancelBtn: UIButton!
    
    /// 确认按钮
    var confirmBtn: UIButton!
    
    /// 取消回调
    var cancelCallback: (() -> Void)?
    
    /// 确认回调
    var confirmCallback: (() -> Void)?
    
    /// 播放器播放停止通知 设置循环播放
    func playerDidFinishPlaying(note: Notification) {
        player.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
        player.play()
    }
    
    /// 重写解决转屏问题
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        videoView.frame = bounds
        playerLayer.frame = videoView.bounds
        cancelBtn.frame = CGRect(x: 10, y: 20, width: 80, height: 44)
        confirmBtn.frame = CGRect(x: UIScreen.main.bounds.width - 66 - 20, y: UIScreen.main.bounds.height - 33 - 20, width: 66, height: 33)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //图片预览
        imageView = UIImageView(frame: bounds)
        imageView.alpha = 0
        addSubview(imageView)
        
        //视频预览
        videoView = UIView(frame: bounds)
        videoView.alpha = 0
        addSubview(videoView)
        
        //视频播放器
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.contentsScale = UIScreen.main.scale
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        
        //重拍按钮
        cancelBtn = UIButton(type: .roundedRect)
        cancelBtn.frame = CGRect(x: 10, y: 20, width: 80, height: 44)
        cancelBtn.setTitle("重拍", for: .normal)
        cancelBtn.setTitleColor(UIColor.white, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelOnClick(btn:)), for: .touchUpInside)
        addSubview(cancelBtn)
        
        //确认按钮
        confirmBtn = UIButton(type: .roundedRect)
        confirmBtn.setTitle("确定", for: .normal)
        confirmBtn.setTitleColor(UIColor.white, for: .normal)
        confirmBtn.layer.borderColor = UIColor.white.cgColor
        confirmBtn.layer.borderWidth = 1.0
        confirmBtn.layer.cornerRadius = 5.0
        confirmBtn.layer.backgroundColor = UIColor.blue.cgColor
        confirmBtn.frame = CGRect(x: UIScreen.main.bounds.width - 66 - 20, y: UIScreen.main.bounds.height - 33 - 20, width: 66, height: 33)
        confirmBtn.addTarget(self, action: #selector(confirmOnClick(btn:)), for: .touchUpInside)
        addSubview(confirmBtn)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(note:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 重拍按钮点击事件
    func cancelOnClick(btn: UIButton) {
        cancelCallback?()
    }
    
    /// 确认按钮点击事件
    func confirmOnClick(btn: UIButton) {
        confirmCallback?()
    }
    
    /// 停止播放
    func stopPlaying() {
        player.pause()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
