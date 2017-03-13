//
//  MKCameraViewController.swift
//  MKCamera
//
//  Created by MaMingkun on 2017/3/10.
//  Copyright © 2017年 MaMingkun. All rights reserved.
//

import UIKit
import AVFoundation

protocol MKCameraViewControllerDelegate: NSObjectProtocol {
    
    func MKCamera(_ viewController: MKCameraViewController, didTakeThePhotos photo: UIImage!)
    func MKCamera(_ viewController: MKCameraViewController, didRecordTheVidew path: URL)
    
}

class MKCameraViewController: UIViewController, MKCameraTakePhotosViewDelegate, UIGestureRecognizerDelegate {
    
    /// 相机控制
    let camera = MKCamera()
    
    /// 相机的预览界面
    var cameraLayer: AVCaptureVideoPreviewLayer!
    
    /// 相机捕捉到的错误信息
    var err: Error?
    
    /// 取消按钮
    var cancelBtn: UIButton!
    
    /// 闪光灯按钮
    var flashBtn: UIButton!
    
    /// 更改摄像头按钮
    var changeBtn: UIButton!
    
    /// 拍照和录像按钮
    var takePhotosBtn: MKCameraTakePhotosView!
    
    /// 对焦框
    var focusCursor: MKCameraFocusCursor!
    
    /// 拍照后的预览界面
    var previewView: MKCameraPreviewView!
    
    /// 对焦用到的手势
    var tapRecognizer: UITapGestureRecognizer!
    
    /// 代理回调对象
    weak var delegate: MKCameraViewControllerDelegate?
    
    /// 点击取消按钮的点击事件
    ///
    /// - Parameter btn: 取消按钮
    func cancelBtnOnClick(btn: UIButton) {
        NotificationCenter.default.removeObserver(self)
        dismiss(animated: true) { 
            
        }
        
    }
    
    /// 闪光灯按钮的点击事件
    ///
    /// - Parameter btn: 闪光灯按钮
    func flashBtnOnClick(btn: UIButton) {
        // 根据当前摄像机闪光灯模式切换状态
        switch camera.flashMode {
        case .auto:
            camera.flashMode = .on
            flashBtn.setImage(#imageLiteral(resourceName: "flash_on"), for: .normal)
        case .on:
            camera.flashMode = .off
            flashBtn.setImage(#imageLiteral(resourceName: "flash_off"), for: .normal)
        case .off:
            camera.flashMode = .auto
            flashBtn.setImage(#imageLiteral(resourceName: "flash_auto"), for: .normal)
        }
        
    }
    
    /// 改变摄像头位置按钮的点击事件
    ///
    /// - Parameter btn: 改变位置的按钮
    func changeBtnOnClick(btn: UIButton) {
        switch camera.cameraPosition {
        case .front:
            camera.cameraPosition = .back
        case .back:
            camera.cameraPosition = .front
        }
    }
    
    // 解决旋转屏幕时控件位置不正确的问题
    func orientationChanged(note: Notification) {
        cameraLayer.frame = CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size)
        cancelBtn.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
        flashBtn.frame = CGRect(x: UIScreen.main.bounds.size.width - 10 * 2 - 50 * 2 , y: 10, width: 50, height: 50)
        changeBtn.frame = CGRect(x: UIScreen.main.bounds.size.width - 10 - 50, y: 10, width: 50, height: 50)
        takePhotosBtn.frame = CGRect(x: (UIScreen.main.bounds.width - 64) / 2.0, y: UIScreen.main.bounds.height - 64 - 25, width: 64, height: 64)
        previewView.frame = CGRect(origin: CGPoint.zero, size: UIScreen.main.bounds.size)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(note:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
        
        //对view进行初始化
        do {
            try camera.setupSession()
            
            //相机预览的layer
            cameraLayer = AVCaptureVideoPreviewLayer(session: camera.session)
            cameraLayer.contentsScale = UIScreen.main.scale
            cameraLayer.videoGravity = AVLayerVideoGravityResizeAspect
            cameraLayer.frame = view.bounds
            view.layer.addSublayer(cameraLayer)
            
            //取消按钮
            cancelBtn = UIButton(type: .custom)
            cancelBtn.frame = CGRect(x: 10, y: 10, width: 50, height: 50)
            cancelBtn.setImage(#imageLiteral(resourceName: "cancel"), for: .normal)
            cancelBtn.addTarget(self, action: #selector(cancelBtnOnClick(btn:)), for: .touchUpInside)
            view.addSubview(cancelBtn)
            
            //闪光灯按钮
            flashBtn = UIButton(type: .custom)
            flashBtn.frame = CGRect(x: UIScreen.main.bounds.size.width - 10 * 2 - 50 * 2 , y: 10, width: 50, height: 50)
            flashBtn.setImage(#imageLiteral(resourceName: "flash_off"), for: .normal)
            flashBtn.addTarget(self, action: #selector(flashBtnOnClick(btn:)), for: .touchUpInside)
            view.addSubview(flashBtn)
            
            //改变镜头按钮
            changeBtn = UIButton(type: .custom)
            changeBtn.frame = CGRect(x: UIScreen.main.bounds.size.width - 10 - 50, y: 10, width: 50, height: 50)
            changeBtn.setImage(#imageLiteral(resourceName: "change"), for: .normal)
            changeBtn.addTarget(self, action: #selector(changeBtnOnClick(btn:)), for: .touchUpInside)
            view.addSubview(changeBtn)
            
            //拍照按钮
            takePhotosBtn = MKCameraTakePhotosView()
            takePhotosBtn.delegate = self
            takePhotosBtn.frame = CGRect(x: (UIScreen.main.bounds.width - 64) / 2.0, y: UIScreen.main.bounds.height - 64 - 25, width: 64, height: 64)
            view.addSubview(takePhotosBtn)
            
            //对焦框
            focusCursor = MKCameraFocusCursor(frame: CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0))
            focusCursor.alpha = 0.0
            view.addSubview(focusCursor)
            
            //拍摄完成后的预览view
            previewView = MKCameraPreviewView(frame: view.bounds)
            previewView.alpha = 0.0
            //预览view重拍按钮的回调
            previewView.cancelCallback = { [unowned self] in
                self.previewView.alpha = 0.0
                self.previewView.stopPlaying()
                self.tapRecognizer.isEnabled = true
            }
            //预览view确认按钮的回调
            previewView.confirmCallback = { [unowned self] in
                NotificationCenter.default.removeObserver(self)
                //完成后回调给代理
                switch self.previewView.previewType {
                case .videos:
                    if self.previewView.videoPath != nil {
                        self.delegate?.MKCamera(self, didRecordTheVidew: self.previewView.videoPath!)
                    }
                case .photos:
                    if self.previewView.image != nil {
                        self.delegate?.MKCamera(self, didTakeThePhotos: self.previewView.image?.fixOrientation())
                    }
                }
            }
            view.addSubview(previewView)
            
            //点击手势
            tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewOnTap(recognizer:)))
            view.addGestureRecognizer(tapRecognizer)
            tapRecognizer.delegate = self
            
        }catch {
            //捕捉到错误
            err = error
            
            print(error)
        }
        
    }
    
    deinit {
        camera.stopSession()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        //如果发现设备是模拟器 则弹出窗口提示
        if err != nil {
            
            switch err! {
            case MKCamera.CameraError.isSimulator:
                let alertVc = UIAlertController(title: "提示", message: "模拟器不支持相机，请用真机测试", preferredStyle: .alert)
                let action = UIAlertAction(title: "确定", style: .default, handler: nil)
                
                alertVc.addAction(action)
                present(alertVc, animated: true, completion: nil)
            default:
                break;
            }
            
        }
        
        camera.startSession()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// 对焦手势的事件
    ///
    /// - Parameter recognizer: 点击手势
    func viewOnTap(recognizer: UITapGestureRecognizer) {
        //获取当前点坐标
        let location = recognizer.location(in: view)
        
        //改变对焦框位置
        focusCursor.center = location
        
        //添加对焦框动画
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1, 1 ,0 ]
        opacityAnimation.keyTimes = [0, 0.8, 1]
        
        let transformAnimation = CAKeyframeAnimation(keyPath: "transform")
        transformAnimation.values = [CATransform3DMakeScale(1.3, 1.3, 1.0) , CATransform3DMakeScale(1.0, 1.0, 1.0) , CATransform3DMakeScale(1.0, 1.0, 1.0)]
        transformAnimation.keyTimes = [0, 0.1, 1]
        
        let animation = CAAnimationGroup()
        animation.animations = [opacityAnimation, transformAnimation]
        animation.duration = 2
        focusCursor.layer.add(animation, forKey: "anim")
        
        //通过相机layer得到正确的点
        let interestPoint = cameraLayer.captureDevicePointOfInterest(for: location)
        
        //设置焦点应用设置
        camera.setCameraFocusAndExposurePoint(interestPoint)
        
    }
    
    // MARK: - tapRecognizer delegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === tapRecognizer {
            //过滤按钮位置的手势导致不需要的对焦
            let point = gestureRecognizer.location(in: view)
            
            if takePhotosBtn.frame.contains(point) {
                return false
            }
            
            return true
        }
        
        return true
    }
    
    // MARK: - takePhotosBtn delegate
    
    func takePhotosViewDidTriggerPhotos(_ photosView: MKCameraTakePhotosView) {
        photosView.isUserInteractionEnabled = false
        //调用相机的拍照方法
        camera.takePhotos { [unowned self] (result, error) in
            photosView.isUserInteractionEnabled = true
            //显示结果
            if result != nil {
                self.previewView.alpha = 1
                self.previewView.previewType = .photos
                self.previewView.image = result
                self.tapRecognizer.isEnabled = false
            }
            
            
            
        }
    }
    
    func takePhotosViewDidBeginRecord(_ photosView: MKCameraTakePhotosView) {
        //开始录像
        camera.startRecording { [unowned self] in
            self.takePhotosBtn.startTimer()
        }
    }
    
    func takePhotosViewDidEndRecord(_ photosView: MKCameraTakePhotosView, isCancelled: Bool) {
        //结束录像
        camera.stopRecording { [unowned self] (fileUrl, error) in
            //显示结果
            if fileUrl != nil {
                self.previewView.alpha = 1
                self.previewView.previewType = .videos
                self.previewView.videoPath = fileUrl
                self.tapRecognizer.isEnabled = false
            }
            
        }
    }
    // 重写该方法隐藏statusBar
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    // 重写以下方法控制屏幕不旋转
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .portrait
    }
    
    override var shouldAutorotate: Bool{
        return false
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
