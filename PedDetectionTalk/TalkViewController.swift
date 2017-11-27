//
//  ViewController.swift
//  Pedestrian Detection
//
//  Created by Brendon Warwick on 22/11/2017.
//  Copyright © 2017 BW. All rights reserved.
//

import UIKit
import AVFoundation
import CoreGraphics
import Vision

// 1) import UIKit, AVFoundation, CoreGraphics, Vision
// 2) Add a viewDidLoad() with setupCoreImage() and setupCamera()
// 3) Hook up cameraImageParentView
// 4) Implement setupCamera
// 5) Implement resizePreviewLayer()
// 6) Add TinyYOLO
// 7) Add all the attributes we will be using (resizedBuffer, videoCapture, bodyRequest, bodies)
// 8) Implement VideoCaptureDelegate and send print statement in findBodies(in:)
// 9) Implement findBodies() and the completion bodyRequestDidComplete(request: VNRequest, error: Error?)
// 10) Implement bodyRequestDidComplete(request: VNRequest, error: Error?)
// 11) Implement getBodies(from:) showing normalized coordinatesa in the process

class ViewController: UIViewController {
    
    // MARK: - Attributes
    
    var resizedPixelBuffer: CVPixelBuffer?
    let yolo = YOLO()
    var videoCapture: VideoCapture!
    var cameraImagePreviewSize: CGSize!
    var bodyRequest: VNCoreMLRequest!
    var bodies = [CGRect]()
    
    // MARK: - Outlets
    
    @IBOutlet weak var cameraImagePreview: UIView!
    
    // MARK: - Initialization & Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCoreImage()
        setUpCamera()
    }
    
    func setUpCoreImage() {
        let status = CVPixelBufferCreate(nil, YOLO.inputWidth, YOLO.inputHeight,
                                         kCVPixelFormatType_32BGRA, nil,
                                         &resizedPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create resized pixel buffer", status)
        }
        
        guard let visionModel = try? VNCoreMLModel(for: yolo.model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        bodyRequest = VNCoreMLRequest(model: visionModel, completionHandler: bodyRequestDidComplete)
        bodyRequest.imageCropAndScaleOption = .scaleFill
    }
    
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 50
        videoCapture.setUp(sessionPreset: AVCaptureSession.Preset.vga640x480) { success in
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.cameraImagePreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = cameraImagePreview.bounds
        cameraImagePreviewSize = cameraImagePreview.bounds.size
    }
    
    // MARK: - Body Detection
    
    func findBodies(in pixelBuffer: CVPixelBuffer) {
        // Vision will automatically resize the input image.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([bodyRequest])
    }
    
    func bodyRequestDidComplete(request: VNRequest, error: Error?) {
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue {
            
            let boundingBoxes = yolo.computeBoundingBoxes(features: features)
            self.bodies = getBodies(from: boundingBoxes)
            self.drawBodies()
        }
    }
    
    private func getBodies(from predictions: [YOLO.Prediction]) -> [CGRect] {

        var bodies = [CGRect]()
        
        for prediction in predictions {
            // The labels for the 20 classes detected by the YOLO network. We use this to isolate "person".
            if (labels[prediction.classIndex] == "person"){
                /** The predicted bounding box is in the coordinate space of the input
                 * image, which is a square image of 416x416 pixels. We want to show it
                 * on the video preview, which is as wide as the screen and has a 4:3
                 * aspect ratio. The video preview also may be letterboxed at the top
                 * and bottom.
                 * When we present the image in AspectFill, the vertical letterboxes are filled
                 * and the image fills the display (16:9), but the sides overflow.
                 * Therefore the width is 3h/4, and the overflow is the diff in widths over 2 either side
                 **/
                
                let height = cameraImagePreviewSize!.height
                let width = (height * 3) / 4
                let scaleX = width / CGFloat(YOLO.inputWidth)
                let scaleY = height / CGFloat(YOLO.inputHeight)
                let offset = (width-cameraImagePreviewSize!.width)/2
                
                // Translate and scale the rectangle to our own coordinate system.
                var rect = prediction.rect
                rect.origin.x *= scaleX
                rect.origin.y *= scaleY
                rect.origin.x -= offset
                rect.size.width *= scaleX
                rect.size.height *= scaleY
                
                bodies.append(rect)
            }
        }
        
        return bodies
    }
}

// MARK: - Video Capture Delegate

extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, rawSampleBuffer: CMSampleBuffer, timestamp: CMTime) {
        if let pixelBuffer = pixelBuffer {
            // For better throughput, perform the prediction on a background queue
            // instead of on the VideoCapture queue.
            
            // You can use a semaphore (DispatchSemaphore(value: Integer)) here to block the capture queue and
            // drop frames when Core ML can't keep up.
            DispatchQueue.global().async { self.findBodies(in: pixelBuffer) }
        }
    }
}
