//
//  ViewController.swift
//  PedDetection
//
//  Created by Brendon Warwick on 27/11/2017.
//  Copyright © 2017 BW. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import Vision

class ViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var cameraImagePreview: UIView!
    
    // MARK: - Attributes
    
    var cameraImagePreviewSize: CGSize!
    var videoCapture: VideoCapture!
    var yolo = YOLO()
    var bodyRequest: VNCoreMLRequest!
    var resizedPixelBuffer: CVBuffer?
    var bodies = [CGRect]()

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupML()
    }
    
    override func viewWillLayoutSubviews() {
        resizePreviewLayer()
    }

    func setupCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            if success {
                if let previewLayer = self.videoCapture.previewLayer {
                    self.cameraImagePreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
            }
            
            self.videoCapture.start()
        }
    }
    
    func setupML() {
        let status = CVPixelBufferCreate(nil, YOLO.inputWidth, YOLO.inputHeight, kCVPixelFormatType_32BGRA, nil, &resizedPixelBuffer)
        
        if status != kCVReturnSuccess {
            print("Could not create pixel buffer")
        }
        
        guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
            print("Could not create model")
            return
        }
        
        bodyRequest = VNCoreMLRequest(model: visionModel, completionHandler: bodyRequestDidComplete)
        bodyRequest.imageCropAndScaleOption = .scaleFill
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = cameraImagePreview.bounds
        cameraImagePreviewSize = cameraImagePreview.bounds.size
    }

    // MARK: - Body Detection
    
    func findBodies(in pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([bodyRequest])
    }
    
    func bodyRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue {
            
            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
            self.bodies = getBodies(predictions: boundingBoxes)
            self.draw(bodies: self.bodies)
        }
    }
    
    func getBodies(predictions: [YOLO.Prediction]) -> [CGRect] {
        var correctBodies = [CGRect]()
        
        for prediction in predictions {
            if labels[prediction.classIndex] == "person" {
                // Abnormalize coordinates
                let h = cameraImagePreviewSize!.height
                let w = (h * 3) / 4
                let scaleX = w / CGFloat(YOLO.inputWidth)
                let scaleY = h / CGFloat(YOLO.inputHeight)
                let offset = (w-cameraImagePreviewSize.width)/2
                
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.x -= offset
                rect.size.width *= scaleX
                rect.size.height *= scaleY
                
                correctBodies.append(rect)
            }
        }
        return correctBodies
    }
}

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, videoFrame: CVPixelBuffer?, rawSampleBuffer: CMSampleBuffer, timestamp: CMTime) {
        if let pixelBuffer = videoFrame {
            // Asyncronously find bodies in the frame
            DispatchQueue.main.async {
                self.findBodies(in: pixelBuffer)
            }
        }
    }
}
