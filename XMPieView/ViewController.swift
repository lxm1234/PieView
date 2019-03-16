//
//  ViewController.swift
//  XMPieView
//
//  Created by lxm on 2019/3/16.
//  Copyright © 2019 lixiaomeng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    fileprivate var chartWidth = UIScreen.main.bounds.width - 20
    fileprivate var charHeight: CGFloat = 300
    fileprivate var segmentDataArray:[CGFloat] = [2,2,3,1,4]
    fileprivate var segmentTitleArray = ["提莫","拉克丝","皇子","EZ","布隆"]
    fileprivate var segmentColorArray = [UIColor.red,UIColor.orange,UIColor.green,UIColor.brown]
    fileprivate var chartView: PieView?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.loadPieChartView()
    }

    func loadPieChartView() {
        //包含文本的视图frame
        var config = PieView.PieConfig()
        config.centerType = .topMiddle
        config.canClick = true
        config.animtionType = .none
        config.centerXPosition = 70
        chartView?.config.hideText = true
        chartView = PieView(frame: CGRect(x: 10, y: 100, width: chartWidth, height: charHeight), config: config)
        //数据源
        chartView?.segmentDataArr = self.segmentDataArray
        //颜色数组，若不传入，则为随即色
        chartView?.segmentColorArr = self.segmentColorArray
        //标题，若不传入，则为“其他”
        chartView?.segmentTitleArr = self.segmentTitleArray
        chartView?.backgroundColor = UIColor.white
        chartView?.clickBlock = {(index) in
            print("Click Index:\(index)")
        }
        chartView?.showCustomView(in: self.view)
    }

    @IBAction func loadNoAnimation(_ sender: Any) {
        chartView?.config.animtionType = .none
//        chartView?.config.canClick = false
        chartView?.config.innerCircleR = 0
        chartView?.updatePieView()
    }
    @IBAction func loadAnimationOne(_ sender: Any) {
        chartView?.config.animtionType = .one
        chartView?.updatePieView()
    }
    @IBAction func loadAnimationTwo(_ sender: Any) {
        chartView?.config.animtionType = .together
        chartView?.updatePieView()
    }
    
}

