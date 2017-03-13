//
//  MKCamera.swift
//  MKCamera
//
//  Created by MaMingkun on 2017/3/10.
//  Copyright © 2017年 MaMingkun. All rights reserved.
//

import UIKit
import AVFoundation

class MKCamera: NSObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {

    enum CameraError: Error {
        case cameraDeviceIsNull, audioDeviceIsNull, isSimulator, imageIsNil
    }
    
    enum FlashMode {
        case on, off, auto
    }
    
    enum CameraPosition {
        case back, front
    }
    
    /// 用来判断是否是模拟器的
    private struct Platform {
        static let isSimulator: Bool = {
            var isSim = false
            #if arch(i386) || arch(x86_64)
                isSim = true
            #endif
            return isSim
        }()
    }
    
    /// 自定义一个拍照的回调
    typealias CapturePhotosCallback = (UIImage?, Error?) -> Void
    
    /// 自定义录制开始的回调
    typealias RecordStartCallback = () -> Void
    
    /// 自定义录制结束的回调
    typealias RecordStopCallback = (URL?, Error?) -> Void
    
    /// 摄像机的会话
    let session = AVCaptureSession()
    
    /// 当前摄像头
    var currentVideoDevice: AVCaptureDevice?
    
    /// 当前麦克风
    var currentAudioDevice: AVCaptureDevice?
    
    /// 摄像头输入
    var videoDeviceInput: AVCaptureDeviceInput?
    
    /// 麦克风输入
    var audioDeviceInput: AVCaptureDeviceInput?
    
    /// 拍照输出
    var photoOutput: AVCapturePhotoOutput?
    
    /// 录像视频输出
    var movieOutput: AVCaptureMovieFileOutput?
    
    /// 拍完照后的回调
    var captureCallback: CapturePhotosCallback?
    
    /// 开始录制的回调
    var startCallback: RecordStartCallback?
    
    /// 结束录制的回调
    var stopCallback: RecordStopCallback?
    
    /// 闪光灯模式
    var flashMode = FlashMode.off
    
    /// 视频保存路径  保存至临时目录
    static var movieFileUrl: URL {
        
        let tmpPath = NSTemporaryDirectory() as NSString
        
        let filePath = tmpPath.appendingPathComponent("mkvideo.mov")
        
        return URL(fileURLWithPath: filePath)
        
    }
    
    var cameraPosition: CameraPosition = .back {
        didSet{
            let position: AVCaptureDevicePosition
            if cameraPosition == .back {
                position = .back
            } else {
                position = .front
            }
            
            //获取设备
            
            guard let newDevice = getVideoDevice(with: position) else { return }
            
            guard let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
            
            session.beginConfiguration()
            //删除旧输出
            session.removeInput(videoDeviceInput)
            //添加新输出
            if session.canAddInput(newInput) {
                session.addInput(newInput)
            }
            currentVideoDevice = newDevice
            videoDeviceInput = newInput
            
            session.commitConfiguration()
            
        }
    }
    
    
    /// 初始化全局会话
    ///
    /// - Throws: 抛出可能出现的异常
    func setupSession() throws {
        
        //判断是否是模拟器 如果是模拟器则抛出异常
        guard Platform.isSimulator == false else {
            throw CameraError.isSimulator
        }
        
        //添加摄像头
        currentVideoDevice = getVideoDevice(with: .back)
        
        guard currentVideoDevice != nil else {
            throw CameraError.cameraDeviceIsNull
        }
        
        videoDeviceInput = try AVCaptureDeviceInput(device: currentVideoDevice)
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        //添加麦克风
        
        currentAudioDevice = getAudioDevice(with: .unspecified)
        
        guard currentAudioDevice != nil else {
            throw CameraError.audioDeviceIsNull
        }
        
        audioDeviceInput = try AVCaptureDeviceInput(device: currentAudioDevice)
        
        if session.canAddInput(audioDeviceInput) {
            session.addInput(audioDeviceInput)
        }
        
        //添加拍照输出
        
        photoOutput = AVCapturePhotoOutput()
        
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        //添加录制视频输出
        
        movieOutput = AVCaptureMovieFileOutput()
        
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
        
    }
    
    /// 开始session工作
    func startSession() {
        session.startRunning()
    }
    
    /// 结束session工作
    func stopSession() {
        session.stopRunning()
    }
    
    func setCameraFocusAndExposurePoint(_ point: CGPoint) {
        guard let device = currentVideoDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
            }
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
            }
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }
            
            device.unlockForConfiguration()
        } catch {
            print("set focus point and exposure point failed: \(error)")
        }
        
    }
    
    /// 拍照
    ///
    /// - Parameter results: 拍照完成后的结果回调
    func takePhotos(results: CapturePhotosCallback?) {
        
        let photoSettings = AVCapturePhotoSettings()
        
        switch flashMode {
        case .auto:
            photoSettings.flashMode = .auto
        case .off:
            photoSettings.flashMode = .off
        case .on:
            photoSettings.flashMode = .on
        }
        
        captureCallback = results
        
        photoOutput?.capturePhoto(with: photoSettings, delegate: self)
        
        
    }
    
    /// 开始录制
    ///
    /// - Parameter callback: 开始录制后的回调
    func startRecording(_ callback: @escaping RecordStartCallback) {
        startCallback = callback
        self.movieOutput?.startRecording(toOutputFileURL: MKCamera.movieFileUrl, recordingDelegate: self)
        
    }
    
    /// 结束录制
    ///
    /// - Parameter callback: 保存完成后的回调 包含保存路径和可能出现的错误
    func stopRecording(_ callback: @escaping RecordStopCallback) {
        stopCallback = callback
        self.movieOutput?.stopRecording()
    }
    
    // MARK: - movieOutput delegate
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        startCallback?()
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        stopCallback?(outputFileURL, error)
    }
    
    // MARK: - photoOutput delegate
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let callBack = captureCallback {
            
            guard photoSampleBuffer != nil else {
                
                callBack(nil ,CameraError.imageIsNil)
                
                return
            }
            
            if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer) {
                
                if let image = UIImage(data: imageData) {
                    callBack(image ,nil)
                } else {
                    callBack(nil ,CameraError.imageIsNil)
                }
                
            } else {
                callBack(nil ,CameraError.imageIsNil)
            }
            
            
        }
        
    }
    
    /// 获取对应位置的摄像头 (私有)
    ///
    /// - Parameter position: 摄像头位置
    /// - Returns: 摄像头 有错返回nil
    private func getVideoDevice(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        //iOS 10 的方法
        let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: position)
        
        guard let devices = discoverySession?.devices else {
            return nil
        }
        
        if devices.count == 0 {
            
            return nil
        }
        
        return devices.first
        
    }
    
    /// 获取对应位置的麦克风 (私有)
    ///
    /// - Parameter position: 麦克风位置(好像只能是.unspecified)
    /// - Returns: 麦克风 有错返回nil
    private func getAudioDevice(with position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        let discoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: AVMediaTypeAudio, position: position)
        
        guard let devices = discoverySession?.devices else {
            return nil
        }
        
        if devices.count == 0 {
            
            return nil
        }
        
        return devices.first
        
    }
    

}

extension UIImage {
    
    /// 修复拍照后图片旋转不正确的问题
    ///
    /// - Returns: 修复后的图片
    func fixOrientation() -> UIImage? {
        
        if imageOrientation == .up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down:
            fallthrough
        case .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            break
        case .left:
            fallthrough
        case .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))
            break
        case .right:
            fallthrough
        case .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
            break
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored:
            fallthrough
        case .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored:
            fallthrough
        case .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        default:
            break
        }
        
        let ctx = CGContext.init(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: (cgImage?.bitsPerComponent)!, bytesPerRow: 0, space: (cgImage?.colorSpace)!, bitmapInfo: (cgImage?.bitmapInfo.rawValue)!)
        
        ctx?.concatenate(transform)
        
        switch imageOrientation {
        case .leftMirrored:
            fallthrough
        case .left:
            fallthrough
        case .rightMirrored:
            fallthrough
        case .right:
            ctx?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            break
        default:
            ctx?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        if let cgImage = ctx?.makeImage() {
            
            return UIImage(cgImage: cgImage)
            
        }
        
        return nil
        
    }
}
