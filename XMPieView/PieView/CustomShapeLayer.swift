//
//  CustomShapeLayer.swift
//  XMPieView
//
//  Created by lxm on 2019/3/16.
//  Copyright © 2019 lixiaomeng. All rights reserved.
//

import UIKit

class CustomShapeLayer: CAShapeLayer {
    /**
     *  起始弧度
     **/
    var startAngle: CGFloat = 0
    /**
     *  结束弧度
     **/
    var endAngle: CGFloat = 0
    /**
     *  圆饼半径
     **/
    var radius: CGFloat = 0
    /**
     *  点击偏移量
     **/
    var clickOffset: CGFloat = 0
    /**
     *  是否只有一个模块，多个模块的动画与单个模块的动画不一样
     **/
    var isOneSection: Bool = false
    /**
     *  圆饼layer的圆心
     **/
    var centerPoint: CGPoint = .zero
    /**
     *  内圆半径
     **/
    var innerRadius: CGFloat = 0
    /**
     *  内圆颜色
     **/
    var innerColor: UIColor = .white
    /**
     *  是否点击
     **/
    var isSelected: Bool = false {
        didSet {
            var newCenterPoint = centerPoint
            if self.isOneSection {
                self.dealOneSection(selected: isSelected)
                return
            }
            if self.isSelected {
                let newX = centerPoint.x + CGFloat(cosf(Float((startAngle + endAngle)/2))) * self.clickOffset
                let newY = centerPoint.y + CGFloat(sinf(Float((startAngle + endAngle)/2))) * self.clickOffset
                newCenterPoint = CGPoint.init(x: newX, y: newY)
            }
            //创建一个path
            let path = UIBezierPath.init()
            //起始中心点改一下
            path.move(to: newCenterPoint)
            path.addArc(withCenter: newCenterPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise:true)
            path.addArc(withCenter: newCenterPoint, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: false)
            path.close()
            self.path = path.cgPath
            //添加动画
            let animation = CABasicAnimation()
            animation.keyPath = "path"
            animation.toValue = path
            animation.duration = 0.3
            self.add(animation, forKey: nil)
        }
    }
    
    func dealOneSection(selected: Bool) {
        //创建一个path
        let originPath = UIBezierPath()
        originPath.move(to: centerPoint)
        originPath.addArc(withCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        originPath.addArc(withCenter: centerPoint, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        originPath.close()
        //再创建一个path
        let path = UIBezierPath()
        //起始中心点改一下
        path.move(to: centerPoint)
        path.addArc(withCenter: centerPoint, radius: radius + self.clickOffset, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        path.addArc(withCenter: centerPoint, radius: innerRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.close()
        let animation = CABasicAnimation()
        animation.keyPath = "path"
        animation.duration = 0.3
        if (!self.isSelected) {
            self.path = originPath.cgPath
            animation.fromValue = path
            animation.toValue = originPath
        } else {
            self.path = path.cgPath
            animation.fromValue = originPath
            animation.toValue = path
        }
        self.add(animation, forKey: nil)
    }
}
