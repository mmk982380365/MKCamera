//
//  MKCameraTakePhotosView.swift
//  MKCamera
//
//  Created by MaMingkun on 2017/3/10.
//  Copyright © 2017年 MaMingkun. All rights reserved.
//

import UIKit

protocol MKCameraTakePhotosViewDelegate: NSObjectProtocol {
    func takePhotosViewDidTriggerPhotos(_ photosView: MKCameraTakePhotosView)
    func takePhotosViewDidBeginRecord(_ photosView: MKCameraTakePhotosView)
    func takePhotosViewDidEndRecord(_ photosView: MKCameraTakePhotosView, isCancelled: Bool)
}

class MKCameraTakePhotosView: UIView, CAAnimationDelegate {
    
    /// 中间圆的layer
    class CircleLayer: CALayer {
        
        /// 进度
        @NSManaged var progress: CGFloat
        
        /// 是否显示中间小圆
        @NSManaged var showSmallCircle: Bool
        
        /// 重写该方法 让progress和showSmallCircle值改变时调用setNeedsDisplay()
        override class func needsDisplay(forKey key: String) -> Bool {
            
            if key == "progress" || key == "showSmallCircle" {
                return true
            }
            
            return super.needsDisplay(forKey: key)
        }
        
        /// 重写该方法添加过渡动画
        override func action(forKey event: String) -> CAAction? {
            
            if event == "progress" {
                let animation = CABasicAnimation(keyPath: "progress")
                animation.duration = 0.5
                animation.fromValue = progress
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                return animation
            }
            
            return super.action(forKey: event)
        }
        /// 绘图
        override func draw(in ctx: CGContext) {
            
            let tintColor = UIColor(red: 102.0 / 255.0, green: 204.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0).cgColor
            
            //设置填充色
            ctx.setFillColor(UIColor.white.cgColor)
            
            let largeRadius: CGFloat = bounds.size.width * 0.5
            
            let smallRadius: CGFloat = largeRadius - 6
            
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            
            //白色圆环
            ctx.addArc(center: center, radius: largeRadius, startAngle: 0, endAngle: CGFloat(M_PI) * 2, clockwise: true);
            ctx.drawPath(using: .fill)
            
            //蓝色进度条
            ctx.setFillColor(tintColor)
            ctx.move(to: center)
            ctx.addArc(center: center, radius: largeRadius, startAngle: -CGFloat(M_PI_2), endAngle: (CGFloat(M_PI) * 2.0) * progress - CGFloat(M_PI_2), clockwise: false)
            
            ctx.closePath()
            ctx.drawPath(using: .fill)
            
            //清空中心
            ctx.addArc(center: center, radius: smallRadius, startAngle: 0, endAngle: CGFloat(M_PI) * 2, clockwise: true)
            
            ctx.setBlendMode(.clear)
            
            ctx.drawPath(using: .fill)
            
            if showSmallCircle {
                //显示中间的小圆
                ctx.setBlendMode(.color)
                ctx.setFillColor(tintColor)
                
                let radius: CGFloat = smallRadius - 10
                
                ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat(M_PI) * 2, clockwise: true)
                
                ctx.drawPath(using: .fill)
                
                
            }
            
            
        }
        
        //初始化调用一次setNeedsDisplay()
        override init(layer: Any) {
            super.init(layer: layer)
            setNeedsDisplay()
        }
        
        override init() {
            super.init()
            setNeedsDisplay()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    /// 按钮状态
    ///
    /// - none: 正常状态
    /// - takePhotos: 拍照
    /// - recording: 录像
    enum State {
        case none, takePhotos, recording
    }
    
    /// 重写该方法更改self.layer的class
    override class var layerClass: AnyClass {
        return CircleLayer.self
    }
    
    /// 回调
    weak var delegate: MKCameraTakePhotosViewDelegate?
    
    /// 时间进度 使用kvc方式复制
    var progress: CGFloat {
        set{
            layer.setValue(newValue, forKey: "progress")
        }
        get{
            return layer.value(forKey: "progress") as! CGFloat
        }
    }
    
    /// 按钮状态 控制时间及layer中心小圆的显示
    var state = State.none {
        didSet{
            switch state {
            case .recording:
                layer.setValue(true, forKey: "showSmallCircle")
//                startTimer()
            case .takePhotos:
                layer.setValue(false, forKey: "showSmallCircle")
                stopTimer()
            default:
                layer.setValue(false, forKey: "showSmallCircle")
                stopTimer()
            }
        }
    }
    
    /// 录音最长时间
    var maxTime: TimeInterval = 5.0
    
    /// 当前时间
    var currentTime: TimeInterval = 0
    
    /// 计时器
    var time: Timer?
    
    /// 视图初始化
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        layer.contentsScale = UIScreen.main.scale
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    /// 开始计时
    func startTimer() {
        
        time?.invalidate()
        time = nil
        currentTime = 0
        progress = 0
        time = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeAction(timer:)), userInfo: nil, repeats: true)
        time?.fire()
    }
    
    /// 结束计时
    func stopTimer() {
        currentTime = 0
        progress = 0
        time?.invalidate()
        time = nil
    }
    
    /// 计时器调用事件
    ///
    /// - Parameter timer: 计时器
    func timeAction(timer: Timer) {
        
        currentTime += 1
        
        progress = CGFloat(currentTime / maxTime)
        
        // 若当前时间超过最大值则停止计时
        if currentTime > maxTime {
            stopTimer()
            
            /*
             结束
             
             */
            
            
        }
        
    }
    
    func finishAction() {
        //移除动画
        layer.removeAllAnimations()
        //判断状态
        if state == .recording {
            delegate?.takePhotosViewDidEndRecord(self, isCancelled: false)
        } else if state == .takePhotos {
            delegate?.takePhotosViewDidTriggerPhotos(self)
        }
        //恢复状态
        state = .none
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = layer.transform
        animation.toValue = CATransform3DIdentity
        animation.duration = 0.5
        layer.add(animation, forKey: "stop")
        layer.transform = CATransform3DIdentity
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //动画结束前是拍照
        state = .takePhotos
        
        
        //添加动画
        let transform = CATransform3DMakeScale(1.5, 1.5, 1)
        layer.transform = transform
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = CATransform3DIdentity
        animation.toValue = transform
        animation.duration = 0.5
        animation.delegate = self
        animation.setValue("start", forKey: "opt")
        layer.add(animation, forKey: "start")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        finishAction()
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        layer.removeAllAnimations()
        //判断状态
        if state == .recording {
            delegate?.takePhotosViewDidEndRecord(self, isCancelled: true)
        }
        
        state = .none
        
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = layer.transform
        animation.toValue = CATransform3DIdentity
        animation.duration = 0.5
        layer.add(animation, forKey: "stop")
        layer.transform = CATransform3DIdentity
    }
    
    //动画代理 flag若为true 则进入录制状态
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        if let str = anim.value(forKey: "opt") as? String {
            
            if str == "start" && flag {
                state = .recording
                delegate?.takePhotosViewDidBeginRecord(self)
            }
            
        }
        
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    
}


