//
//  MKCameraFocusCursor.swift
//  MKCamera
//
//  Created by MaMingkun on 2017/3/13.
//  Copyright © 2017年 MaMingkun. All rights reserved.
//

import UIKit

class MKCameraFocusCursor: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //设置背景色为透明
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        //画图
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        ctx.setShouldAntialias(true)
        ctx.setAllowsAntialiasing(true)
        ctx.setLineWidth(1.0)
        ctx.setStrokeColor(UIColor.white.cgColor)
        
        let width = frame.size.width
        let height = frame.size.height
        
        ctx.addRect(rect)
        
        ctx.move(to: CGPoint(x: width / 2.0, y: 0.0))
        ctx.addLine(to: CGPoint(x: width / 2.0, y: 6.0))
        
        ctx.move(to: CGPoint(x: width / 2.0, y: height))
        ctx.addLine(to: CGPoint(x: width / 2.0, y: height - 6.0))
        
        ctx.move(to: CGPoint(x: 0.0, y: height / 2.0))
        ctx.addLine(to: CGPoint(x: 6.0, y: height / 2.0))
        
        ctx.move(to: CGPoint(x: width, y: height / 2.0))
        ctx.addLine(to: CGPoint(x: width - 6.0, y: height / 2.0))
        
        ctx.strokePath()
        
    }
    

}
