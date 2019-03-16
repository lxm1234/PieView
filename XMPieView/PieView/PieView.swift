//
//  PieView.swift
//  XMPieView
//
//  Created by lxm on 2019/3/16.
//  Copyright © 2019 lixiaomeng. All rights reserved.
//

import UIKit

class PieView: UIView {
    //饼状图数据数组
    var segmentDataArr: [CGFloat] = []
    //饼状图标题数组
    var segmentTitleArr: [String] = []
    //饼状图颜色数组
    var segmentColorArr: [UIColor] = []
    
    fileprivate var pieShapeLayerArray: [CustomShapeLayer] = []
    fileprivate var segmentPathArray: [UIBezierPath] = []
    fileprivate var segmentCoverLayerArray: [CAShapeLayer] = []
    fileprivate var colorPointArray: [CAShapeLayer] = []
    fileprivate var colorRightOriginPoint: CGPoint = .zero
    fileprivate var pieR: CGFloat = 0
    fileprivate var pieCenter: CGPoint = .zero
    fileprivate var coverCircleLayer: CAShapeLayer?
    fileprivate var whiteLayer: CAShapeLayer?
    fileprivate var selectedIndex: Int = 0
    //文本数组
    fileprivate var finalTextArray: [String] = []
    
    var clickBlock: ((Int)->Void)?
    
    var config: PieConfig!
    
    init(frame: CGRect,config: PieConfig) {
        super.init(frame: frame)
        self.config = config
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        if !self.config.hideText {
            self.drawRightText()
        }
    }
    
    func drawRightText() {
        let viewWidth = self.bounds.size.width
        let textX = self.colorRightOriginPoint.x + self.config.colorHeight
        let textY = self.colorRightOriginPoint.y
        var textColor = UIColor.black
        var attrs: [NSAttributedString.Key : Any] = [:]
        for (i,text) in self.finalTextArray.enumerated() {
            if self.config.isSameColor,i < self.segmentColorArr.count {
                textColor = self.segmentColorArr[i]
            }
            let textUseHeight = text.boundHeight(fontSize: self.config.textFontSize, width: 1000)
            let textOffset = (self.config.textHeight - textUseHeight)/2
            attrs[.foregroundColor] = textColor
            attrs[.font] = UIFont.systemFont(ofSize: self.config.textFontSize)
            (text as NSString).draw(in: CGRect.init(x: textX, y: textY+self.config.textSpace*CGFloat(i)+self.config.textHeight*CGFloat(i)+textOffset, width: viewWidth - textX, height: self.config.textHeight), withAttributes: attrs)
        }
    }
    
    //添加视图
    func showCustomView(in superView: UIView) {
        if (self.segmentColorArr.count == 0) {
            self.loadRandomColorArray()
        }
        superView.addSubview(self)
        if self.config.animtionType == .none {
            self.loadNoAnimation()
        } else if self.config.animtionType == .together {
            self.loadTogetherAnimation()
        } else if self.config.animtionType == .one {
            self.loadOneAnimation()
        }
    }

    func updatePieView() {
        whiteLayer?.removeFromSuperlayer()
        for layer in pieShapeLayerArray {
            layer.removeFromSuperlayer()
        }
        for layer in self.colorPointArray {
            layer.removeFromSuperlayer()
        }
        for layer in self.segmentCoverLayerArray {
            layer.removeFromSuperlayer()
        }
        self.colorPointArray.removeAll()
        pieShapeLayerArray.removeAll()
        segmentPathArray.removeAll()
        segmentCoverLayerArray.removeAll()
        self.finalTextArray.removeAll()
        self.setNeedsLayout()
        if self.config.animtionType == .none {
            self.loadNoAnimation()
        } else if self.config.animtionType == .together {
            self.loadTogetherAnimation()
        } else if self.config.animtionType == .one {
            self.loadOneAnimation()
        }
    }
    //如果没有分配颜色，颜色随机获取
    func loadRandomColorArray() {
        for _ in 0..<self.segmentDataArr.count {
            let color = self.loadRandomColor()
            self.segmentColorArr.append(color)
        }
    }
    func loadRandomColor() -> UIColor {
        let red = self.getRandomNumber(from: 1, to: 255)
        let green = self.getRandomNumber(from: 1, to: 255)
        let blue = self.getRandomNumber(from: 1, to: 255)
        return UIColor.init(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1.0)
    }
    
    func getRandomNumber(from: Int,to: Int) -> Int {
        return from + Int(arc4random()) % (to - from)
    }
    //没有动画的饼状图的绘制
    func loadNoAnimation() {
        self.loadTextContent()
        self.loadPieView()
    }
    func loadTextContent() {
        self.loadFinalText()
        self.config.centerType = .middleLeft
        self.loadRightTextAndColor()
    }
    
    func loadPieView() {
        
        //放置layer的主layer，如果没有这个layer，那么设置背景色就无效了，因为被mask了。
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.frame = self.bounds
        self.layer.addSublayer(backgroundLayer)
        //半径
        let maxRadius = min(self.bounds.width, self.bounds.height)/2
        pieR = min(self.config.pieRadius, maxRadius)
        //圆心
        self.loadPieCenter()
        if self.config.centerXPosition > 0 {
            pieCenter = CGPoint.init(x: self.config.centerXPosition, y: pieCenter.y)
        }
        if self.config.centerYPosition > 0 {
            pieCenter = CGPoint.init(x: pieCenter.x, y: self.config.centerYPosition)
        }
        //数据总值
        let totalValue = self.segmentDataArr.reduce(0, +)
        var currentRadian = -CGFloat.pi/2
        for (i,value) in self.segmentDataArr.enumerated() {
            //根据当前数值的占比，计算得到当前的弧度
            let radian = self.loadPercentRadian(current: value, total: totalValue)
            //弧度结束值 初始值＋当前弧度
            let endAngle = currentRadian + radian
            //贝塞尔曲线
            let path = UIBezierPath()
            path.move(to: self.pieCenter)
            //圆弧 默认最右端为0，YES时为顺时针。NO时为逆时针。
            path.addArc(withCenter: pieCenter, radius: pieR, startAngle: currentRadian, endAngle: endAngle, clockwise: true)
            path.addArc(withCenter: pieCenter, radius: self.config.innerCircleR, startAngle: endAngle, endAngle: currentRadian, clockwise: false)
            //添加到圆心直线
            path.addLine(to: pieCenter)
            //路径闭合
            path.close()
            //当前shapeLayer的遮罩
            
            let coverPath = UIBezierPath(arcCenter: pieCenter, radius: pieR/2 + self.config.clickOffsetSpace, startAngle: currentRadian, endAngle: endAngle, clockwise: true)
            segmentPathArray.append(coverPath)
            
            let radiusLayer = CustomShapeLayer()
            //设置layer的路径
            radiusLayer.centerPoint = pieCenter
            radiusLayer.startAngle = currentRadian
            radiusLayer.endAngle = endAngle
            radiusLayer.radius = pieR
            radiusLayer.innerColor = self.config.innerColor
            radiusLayer.innerRadius = self.config.innerCircleR
            radiusLayer.path = path.cgPath
            
            currentRadian = endAngle
            var currentColor = UIColor.cyan
            if i < self.segmentColorArr.count {
                currentColor = self.segmentColorArr[i]
            }
            radiusLayer.strokeColor = self.config.boardColor.cgColor
            radiusLayer.fillColor = currentColor.cgColor
            radiusLayer.lineWidth = self.config.boardWidth
            pieShapeLayerArray.append(radiusLayer)
            backgroundLayer.addSublayer(radiusLayer)
        }
        //贝塞尔曲线
        let innerPath = UIBezierPath()
         //圆弧 默认最右端为0，YES时为顺时针。NO时为逆时针。
        innerPath.addArc(withCenter: pieCenter, radius: pieR/2 + self.config.clickOffsetSpace, startAngle: -CGFloat.pi/2, endAngle: CGFloat.pi*3/2, clockwise: true)
        self.coverCircleLayer = CAShapeLayer()
        //设置layer的路径
        self.coverCircleLayer?.lineWidth = pieR + self.config.clickOffsetSpace * 2
        self.coverCircleLayer?.strokeStart = 0
        self.coverCircleLayer?.strokeEnd = 1
        //Must 如果stroke没有颜色，那么动画没法进行了
        self.coverCircleLayer?.strokeColor = UIColor.black.cgColor
        //决定内部的圆是否显示,如果clearColor，则不会在动画开始时就有各个颜色的、完整的内圈。
        self.coverCircleLayer?.fillColor = UIColor.clear.cgColor
        self.coverCircleLayer?.path = innerPath.cgPath
        backgroundLayer.mask = self.coverCircleLayer
        //内圈的小圆
        self.addInnserCircle()
    }
    
    func loadFinalText() {
        //数据总值
        let totalValue = segmentDataArr.reduce(0, +)
        for i in 0..<self.segmentDataArr.count {
            let data = self.segmentDataArr[i]
            let rate = data/totalValue
            if i < self.segmentTitleArr.count {
                let title = self.segmentTitleArr[i]
                let text = String.init(format: " \(title) %.1f%%", rate * 100)
                self.finalTextArray.append(text)
            } else {
                let text = String.init(format: " 其他 %.1f%%", rate * 100)
                self.finalTextArray.append(text)
            }
        }
    }
    
    func loadRightTextAndColor() {
        let viewHeight = self.bounds.size.height
        let viewWidth = self.bounds.size.width
        var maxWidth: CGFloat = 0
        for text in self.finalTextArray {
            let width = text.boundWidth(fontSize: self.config.textFontSize, height: self.config.textHeight)
            if width > maxWidth {
                maxWidth = width
            }
        }
        let colorOriginX = viewWidth - maxWidth - self.config.colorHeight - self.config.textRightSpace
        let colorOriginY = (viewHeight - (self.config.textHeight * CGFloat(self.finalTextArray.count) + self.config.textSpace * CGFloat(self.finalTextArray.count - 1)))/2
        self.colorRightOriginPoint = CGPoint.init(x: colorOriginX, y: colorOriginY)
        for (i,_) in self.finalTextArray.enumerated() {
            let colorLayer = CAShapeLayer()
            let spaceHeight = (self.config.textHeight - self.config.colorHeight)/2
            colorLayer.frame = CGRect.init(x: colorOriginX, y: colorOriginY + self.config.textSpace * CGFloat(i) + self.config.textHeight * CGFloat(i) + spaceHeight , width: self.config.colorHeight, height: self.config.colorHeight)
            var color = UIColor.cyan
            if i < self.segmentColorArr.count {
                color = self.segmentColorArr[i]
            }
            colorLayer.backgroundColor = color.cgColor
            if self.config.isRound {
                colorLayer.cornerRadius = self.config.colorHeight/2
            }
            self.colorPointArray.append(colorLayer)
            self.layer.addSublayer(colorLayer)
        }
    }
    
    func loadPieCenter() {
        let viewHeight = self.bounds.size.height
        let viewWidth = self.bounds.size.width
        //圆心
        pieCenter = CGPoint.init(x: viewWidth/2, y: viewHeight/2)
        switch self.config.centerType {
        case .center:
            pieCenter = CGPoint.init(x: viewWidth/2, y: viewHeight/2)
        case .topLeft:
            pieCenter = CGPoint.init(x: pieR, y: pieR)
        case .topMiddle:
            pieCenter = CGPoint.init(x: viewWidth/2, y: pieR)
        case .topRight:
            pieCenter = CGPoint.init(x: viewWidth - pieR, y: pieR)
        case .middleLeft:
            pieCenter = CGPoint.init(x: pieR, y: viewHeight/2)
        case .middleRight:
            pieCenter = CGPoint.init(x: viewWidth - pieR, y: viewHeight/2)
        case .bottomLeft:
            pieCenter = CGPoint.init(x: pieR, y: viewHeight - pieR)
        case .bottomMiddle:
            pieCenter = CGPoint.init(x: viewWidth/2, y: viewHeight - pieR)
        case .bottomRight:
            pieCenter = CGPoint.init(x: viewWidth - pieR, y: viewHeight - pieR)
        }
    }
    
    func loadPercentRadian(current: CGFloat, total: CGFloat) -> CGFloat {
        let percent = current/total
        return percent * CGFloat.pi*2
    }
    
    func loadTogetherAnimation() {
        if !self.config.hideText {
            self.loadTextContent()
        }
        self.loadCustomPieView()
        for layer in self.segmentCoverLayerArray {
            self.doCustomAnimation(layer: layer)
        }
    }
    
    func loadOneAnimation() {
        if !self.config.hideText {
            self.loadTextContent()
        }
        self.loadPieView()
        self.doCustomAnimation(layer: coverCircleLayer)
    }
    func doCustomAnimation(layer: CAShapeLayer?) {
        let strokeAnimation = CABasicAnimation.init(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.duration = CFTimeInterval(self.config.animationTime > 0 ? self.config.animationTime : 2)
        strokeAnimation.toValue = 1
        strokeAnimation.autoreverses = false
        strokeAnimation.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        strokeAnimation.isRemovedOnCompletion = true
        layer?.add(strokeAnimation, forKey: "strokeEndAnimation")
        layer?.strokeEnd = 1;
    }
    func loadCustomPieView() {
        //半径
        let maxRadius = min(self.bounds.width, self.bounds.height)/2
        pieR = min(self.config.pieRadius, maxRadius)
        //圆心
        self.loadPieCenter()
        if self.config.centerXPosition > 0 {
            pieCenter = CGPoint.init(x: self.config.centerXPosition, y: pieCenter.y)
        }
        if self.config.centerYPosition > 0 {
            pieCenter = CGPoint.init(x: pieCenter.x, y: self.config.centerYPosition)
        }
        //数据总值
        let totalValue = self.segmentDataArr.reduce(0, +)
        var currentRadian = -CGFloat.pi/2
        for (i,value) in self.segmentDataArr.enumerated() {
            let radian = self.loadPercentRadian(current: value, total: totalValue)
            //弧度结束值 初始值＋当前弧度
            let endAngle = currentRadian + radian
            //贝塞尔曲线
            let path = UIBezierPath()
            path.move(to: self.pieCenter)
            //圆弧 默认最右端为0，YES时为顺时针。NO时为逆时针。
            path.addArc(withCenter: pieCenter, radius: pieR, startAngle: currentRadian, endAngle: endAngle, clockwise: true)
            path.addArc(withCenter: pieCenter, radius: self.config.innerCircleR, startAngle: endAngle, endAngle: currentRadian, clockwise: false)
            //添加到圆心直线
            path.addLine(to: pieCenter)
            //路径闭合
            path.close()
            //当前shapeLayer的遮罩
            let coverPath = UIBezierPath(arcCenter: pieCenter, radius: pieR/2 + self.config.clickOffsetSpace, startAngle: currentRadian, endAngle: endAngle, clockwise: true)
            segmentPathArray.append(coverPath)
            let radiusLayer = CustomShapeLayer()
            //设置layer的路径
            radiusLayer.centerPoint = pieCenter
            radiusLayer.startAngle = currentRadian
            radiusLayer.endAngle = endAngle
            radiusLayer.radius = pieR
            radiusLayer.innerColor = self.config.innerColor
            radiusLayer.innerRadius = self.config.innerCircleR
            radiusLayer.path = path.cgPath
            
            currentRadian = endAngle
            var currentColor = UIColor.cyan
            if i < self.segmentColorArr.count {
                currentColor = self.segmentColorArr[i]
            }
            radiusLayer.fillColor = currentColor.cgColor
            pieShapeLayerArray.append(radiusLayer)
            self.layer.addSublayer(radiusLayer)
            
        }
        for (i,path) in self.segmentPathArray.enumerated(){
            let originLayer = pieShapeLayerArray[i]
            let layer = CAShapeLayer()
            layer.lineWidth = pieR + self.config.clickOffsetSpace * 2
            layer.strokeStart = 0
            layer.strokeEnd = 0
            layer.strokeColor = UIColor.black.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.path = path.cgPath
            originLayer.mask = layer
            segmentCoverLayerArray.append(layer)
        }
        self.addInnserCircle()
    }
    func addInnserCircle() {
        //内圈的小圆
        let whitePath = UIBezierPath(arcCenter: pieCenter, radius: self.config.innerCircleR, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        whiteLayer = CAShapeLayer()
        whiteLayer?.path = whitePath.cgPath
        whiteLayer?.fillColor = self.config.innerColor.cgColor
        self.layer.addSublayer(whiteLayer!)
    }
    
    func setSelected(index: Int) {
        self.selectedIndex = index
        if !self.config.canClick {
            return
        }
        if selectedIndex < pieShapeLayerArray.count {
            let layer = pieShapeLayerArray[selectedIndex]
            layer.isSelected = true
            self.dealClickCircle(index: self.selectedIndex)
        }
    }
    func dealClickCircle(index: Int) {
        self.clickBlock?(index)
        if index < self.colorPointArray.count {
            let layer = self.colorPointArray[index]
            let animation = CAKeyframeAnimation.init(keyPath: "transform.scale")
            animation.values = [0.9,2.0,1.5,0.7,1.3,1.0]
            animation.calculationMode = .cubic
            animation.duration = TimeInterval(0.8)
            layer.add(animation, forKey: "scaleAnimation")
        }
    }
    
}

// MARK: - touch
extension PieView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.config.canClick {
            return
        }
        let touchPoint = touches.first?.location(in: self) ?? .zero
        for (i,shapeLayer) in pieShapeLayerArray.enumerated() {
            if self.segmentDataArr.count == 1 {
                shapeLayer.isOneSection = true
            }
            //判断选择区域
            shapeLayer.clickOffset = self.config.clickOffsetSpace
            if shapeLayer.path?.contains(touchPoint, using: .winding, transform: .identity) ?? false {
                if shapeLayer.isSelected {
                    shapeLayer.isSelected = false
                } else {
                    shapeLayer.isSelected = true
                }
                self.dealClickCircle(index: i)
            } else {
                shapeLayer.isSelected = false
            }
        }
    }
}

extension PieView {
    enum PieAnimationType {
        case none //无动画
        case one
        case together
    }
    
    enum PieCenterType {
        case center
        case topLeft
        case topMiddle
        case topRight
        case middleLeft
        case middleRight
        case bottomLeft
        case bottomMiddle
        case bottomRight
        
    }
    
    struct PieConfig {
        /**
         *  圆饼的半径
         **/
        var pieRadius: CGFloat = 60
        /**
         *  是否隐藏文本
         **/
        var hideText: Bool = false
        /**
         *  动画时间
         **/
        var animationTime: CGFloat = 1.0
        /**
         *  动画类型,默认只有一个动画
         **/
        var animtionType: PieAnimationType = .one
        /**
         *  内部圆的半径，默认大圆半径的1/3
         **/
        var innerCircleR: CGFloat = 10
        /**
         *  内部圆的颜色，默认白色
         **/
        var innerColor: UIColor = .white
        /**
         *  圆的位置，默认视图的中心
         **/
        var centerType: PieCenterType = .center
        /**
         *  右侧文本 距离右侧的间距
         **/
        var textRightSpace: CGFloat = 10
        /**
         *  圆心的X位置
         **/
        var centerXPosition: CGFloat = 0
        /**
         *  圆心的Y位置
         **/
        var centerYPosition: CGFloat = 0
        /**
         *  文本的高度，默认20
         **/
        var textHeight: CGFloat = 30
        /**
         *  文本前的颜色模块的高度，默认等同于文本高度
         **/
        var colorHeight: CGFloat = 10
        /**
         *  文本的字号，默认14
         **/
        var textFontSize: CGFloat = 14
        /**
         *  文本的行间距，默认10
         **/
        var textSpace: CGFloat = 20
        /**
         *  文本前的颜色是否为圆
         **/
        var isRound: Bool = true
        /**
         *  是否文本颜色等于模块颜色,默认不一样，文本默认黑色
         **/
        var isSameColor: Bool = false
        /**
         *  是否允许点击
         **/
        var canClick: Bool = false
        /**
         *  点击偏移量，默认15
         **/
        var clickOffsetSpace: CGFloat = 15
        /**
         *  选中的index，不设置的话，没有选中的模块
         **/
        var selectionIndex: Int = 0
        //边框大小
        var boardWidth: CGFloat = 5
        //边框颜色
        var boardColor: UIColor = .white
    }
}

extension String {
    func boundWidth(fontSize: CGFloat, height: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attrStr = NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : font])
        return attrStr.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, context: nil).size.width
    }
    func boundHeight(fontSize: CGFloat, width: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attrStr = NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : font])
        return attrStr.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, context: nil).size.height
    }
}
