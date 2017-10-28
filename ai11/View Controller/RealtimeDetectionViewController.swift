//
//  RealtimeDetectionViewController.swift
//  ai11
//
//  Created by Yeojong Kim on 2017. 10. 26..
//  Copyright © 2017년 Yeojong Kim. All rights reserved.
//

import UIKit
import Vision

class RealtimeDetectionViewController: UIViewController {

    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    var videoCapture: VideoCapture!
    var visionRequestHandler = VNSequenceRequestHandler()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.categoryLabel.text = ""
        self.confidenceLabel.text = ""
        
        let cameraSpec = VideoSpec(fps: 3, size: CGSize(width: 1280, height: 720))
        videoCapture = VideoCapture(cameraType: .back, preferredSpec: cameraSpec, previewContainer: self.cameraView.layer)
        self.videoCapture.imageBufferHandler = { (imageBuffer, timestamp, outputBuffer) in
            self.categoryLabel.text = ""
            self.confidenceLabel.text = ""
            DispatchQueue.global(qos: .userInitiated).async {
                self.detectObject(image: imageBuffer)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let videoCapture = self.videoCapture {
            videoCapture.startCapture()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let videoCapture = self.videoCapture {
            videoCapture.stopCapture()
        }
    }

    func detectObject(image selectedImage: CVImageBuffer) {
        do {
            let vnCoreMLModel = try VNCoreMLModel(for: Inceptionv3().model)
            let request = VNCoreMLRequest(model: vnCoreMLModel, completionHandler: self.handleObejctDetection)
            request.imageCropAndScaleOption = .centerCrop
            try self.visionRequestHandler.perform([request], on: selectedImage)
        } catch {
            print(error)
        }
    }
    
    func handleObejctDetection(request: VNRequest, error: Error?) {
        if let result = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.async {
                self.categoryLabel.text = result.identifier
                self.confidenceLabel.text = "\(String(format: "%.1f", arguments: [result.confidence * 100]))%"
            }
        }
    }
}
