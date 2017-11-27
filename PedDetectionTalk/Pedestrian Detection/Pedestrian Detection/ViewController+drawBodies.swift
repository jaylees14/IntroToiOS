//
//  ViewController+rectDrawer.swift
//  Pedestrian Detection
//
//  Created by Brendon Warwick on 22/11/2017.
//  Copyright © 2017 BW. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

extension ViewController {
    
    func draw(bodies: [CGRect]) {

        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        let sublayers: [CALayer] = videoCapture.previewLayer!.sublayers! as [CALayer]
        
        // Remove previous rects from our view to display updated ones
        for layer in sublayers {
            if layer.name != nil && layer.name == "bodyRect"{
                layer.removeFromSuperlayer()
            }
        }
        
        // Now draw all the new ones (only those which are in view)
        bodies.forEach { body in drawDetectedRectOntoView(rect: body) }
    
        CATransaction.commit()
        
        func drawDetectedRectOntoView(rect: CGRect){
            // Drawing rect returned by CIIDetectorRedrawOptions
            let drawLayer = CAShapeLayer()
            drawLayer.lineWidth = 4.0
            drawLayer.strokeColor = UIColor.red.cgColor
            drawLayer.fillColor = UIColor.red.cgColor
            drawLayer.name = "bodyRect"
            
            videoCapture.previewLayer?.addSublayer(drawLayer)
            drawBezierOnto(drawLayer: drawLayer, rect: rect)
        }
        
        func drawBezierOnto(drawLayer: CAShapeLayer, rect: CGRect){
            let rectPath = UIBezierPath()
            
            // Side 1
            rectPath.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
            rectPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y+rect.height))
            // Side 2
            rectPath.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y+rect.height))
            rectPath.addLine(to: CGPoint(x: rect.origin.x+rect.width, y: rect.origin.y+rect.height))
            // Side 3
            rectPath.move(to: CGPoint(x: rect.origin.x+rect.width, y: rect.origin.y+rect.height))
            rectPath.addLine(to: CGPoint(x: rect.origin.x+rect.width, y: rect.origin.y))
            // Side 4
            rectPath.move(to: CGPoint(x: rect.origin.x+rect.width, y: rect.origin.y))
            rectPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
            
            drawLayer.path = rectPath.cgPath
        }
    }
}

