//
//  FacialAnalysisViewController.swift
//  ai11
//
//  Created by Yeojong Kim on 2017. 10. 26..
//  Copyright © 2017년 Yeojong Kim. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class FacialAnalysisViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var selectedImage: UIImage? {
        didSet {
            self.backgroundImageView.image = self.selectedImage
            self.selectedImageView.image = self.selectedImage
        }
    }
    
    var selectedCIImage: CIImage? {
        get {
            if let selectedImage = self.selectedImage {
                return CIImage(image: selectedImage)
            }
            return nil
        }
    }
    
    var faceImageViews = [UIImageView]()
    var seletedFace: UIImage? {
        didSet {
            if let face = self.seletedFace {
                self.hideAllLabels()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.performFaceAnalysis(selectedImage: face)
                }
            }
        }
    }
    
    var requests = [VNRequest]()
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var facesScrollView: UIScrollView!
    
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderIdentifierLabel: UILabel!
    @IBOutlet weak var genderConfidenceLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var ageIdentifierLabel: UILabel!
    @IBOutlet weak var ageConfidenceLabel: UILabel!
    @IBOutlet weak var emotionLabel: UILabel!
    @IBOutlet weak var emotionIdentifierLabel: UILabel!
    @IBOutlet weak var emotionConfidenceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingActivityIndicatorView.stopAnimating()
        hideAllLabels()
        do {
            let genderModel = try VNCoreMLModel(for: GenderNet().model)
            self.requests.append(VNCoreMLRequest(model: genderModel, completionHandler: handleGenderClassification))
            
            let ageModel = try VNCoreMLModel(for: AgeNet().model)
            self.requests.append(VNCoreMLRequest(model: ageModel, completionHandler: handleAgeClassification))
            
            let emotionModel = try VNCoreMLModel(for: CNNEmotions().model)
            self.requests.append(VNCoreMLRequest(model: emotionModel, completionHandler: handleEmotionClassification))
        } catch {
            print(error)
        }
        
    }

    @IBAction func addPhoto(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let importFromAlbum = UIAlertAction(title: "앨범에서 가져오기", style: .default, handler: {_ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        })
        
        let takePhoto = UIAlertAction(title: "카메라로 찍기", style: .default, handler: {_ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.cameraCaptureMode = .photo
            
            self.present(picker, animated: true, completion: nil)
        })
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        actionSheet.addAction(importFromAlbum)
        actionSheet.addAction(takePhoto)
        actionSheet.addAction(cancel)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let uiImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.selectedImage = uiImage
            self.removeRectangles()
            self.loadingActivityIndicatorView.startAnimating()
            self.removeFaceImageView()
            self.hideAllLabels()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.detectFaces()
            }
        }
    }

    func detectFaces() {
        if let ciImage = self.selectedCIImage {
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            do {
                try requestHandler.perform([detectFaceRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func handleFaces(request: VNRequest, error: Error?) {
        if let faces = request.results as? [VNFaceObservation] {
            for face in faces {
                print("face : \(face.boundingBox)")
            }
            DispatchQueue.main.async {
                self.loadingActivityIndicatorView.stopAnimating()
                self.displayUI(for: faces)
            }
        }
    }
    
    /**
      * 사진에서 인식한 얼굴에 빨간 사각형을 추가함
      * 그리고 ScrollView에 crop해서 인식한 얼굴을 보여 줌.
      */
    func displayUI(for faces: [VNFaceObservation]) {
        if let faceImage = self.selectedImage {
            let imageRect = AVMakeRect(aspectRatio: faceImage.size, insideRect: self.selectedImageView.bounds)
            
            for (index, face) in faces.enumerated() {
                // 얼굴에 빨간 사각형 추가하기
                let width = face.boundingBox.size.width * imageRect.width
                let height = face.boundingBox.size.height * imageRect.height
                let x = face.boundingBox.origin.x * imageRect.width
                let y = imageRect.maxY - (face.boundingBox.origin.y * imageRect.height) - height
                
                print("width : \(width), height : \(height), x : \(x), y : \(y)")
                
                let layer = CAShapeLayer()
                layer.frame = CGRect(x: x, y: y, width: width, height: height)
                layer.borderColor = UIColor.red.cgColor
                layer.borderWidth = 1
                self.selectedImageView.layer.addSublayer(layer)
                
                // 얼굴 crop 해 가져오기
                let cropImageWidth = face.boundingBox.size.width * faceImage.size.width
                let cropImageHeight = face.boundingBox.size.height * faceImage.size.height
                let cropImageX = face.boundingBox.origin.x * faceImage.size.width
                let cropImageY = (1 - face.boundingBox.origin.y) * faceImage.size.height - cropImageHeight
                
                let cropRect = CGRect(x: cropImageX * faceImage.scale, y: cropImageY * faceImage.scale, width: cropImageWidth * faceImage.scale, height: cropImageHeight * faceImage.scale)
                
                if let faceCGImage = faceImage.cgImage?.cropping(to: cropRect) {
                    let faceUIImage = UIImage(cgImage: faceCGImage, scale: faceImage.scale, orientation: .up)
                    let faceImageView = UIImageView(frame: CGRect(x: index * 90, y: 0, width: 80, height: 80))
                    faceImageView.image = faceUIImage
                    faceImageView.isUserInteractionEnabled = true
                    
                    let tap = UITapGestureRecognizer(target: self, action: #selector(FacialAnalysisViewController.handleFaceImageViewTap(_:)))
                    faceImageView.addGestureRecognizer(tap)
                    
                    self.faceImageViews.append(faceImageView)
                    self.facesScrollView.addSubview(faceImageView)
                }
            }
            self.facesScrollView.contentSize = CGSize(width: 90 * faces.count - 10, height: 80)
        }
    }
    
    @objc func handleFaceImageViewTap(_ sender: UITapGestureRecognizer) {
        if let tappedImageView = sender.view as? UIImageView {
            
            for faceImageView in self.faceImageViews {
                faceImageView.layer.borderWidth = 0
                faceImageView.layer.borderColor = UIColor.clear.cgColor
            }
            
            tappedImageView.layer.borderWidth = 3
            tappedImageView.layer.borderColor = UIColor.blue.cgColor
            
            self.seletedFace = tappedImageView.image
        }
    }
    
    func performFaceAnalysis(selectedImage image: UIImage) {
        do {
            for request in self.requests {
                let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                try handler.perform([request])
            }
        } catch {
            print(error)
        }
    }
    
    func handleGenderClassification(request: VNRequest, error: Error?) {
        if let genderObservation = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.async {
                self.hideGenderLabels(hide: false)
                self.genderIdentifierLabel.text = "\(genderObservation.identifier)"
                self.genderConfidenceLabel.text = "\(String(format: "%.1f", genderObservation.confidence * 100))%"
                print("gender : \(genderObservation.identifier), confidence : \(genderObservation.confidence)")
            }
        }
    }
    
    func handleAgeClassification(request: VNRequest, error: Error?) {
        if let ageObservation = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.async {
                self.hideAgeLabels(hide: false)
                self.ageIdentifierLabel.text = "\(ageObservation.identifier)"
                self.ageConfidenceLabel.text = "\(String(format: "%.1f", ageObservation.confidence * 100))%"
                print("age : \(ageObservation.identifier), confidence : \(ageObservation.confidence)")
            }
        }
    }
    
    func handleEmotionClassification(request: VNRequest, error: Error?) {
        if let emotionObservation = request.results?.first as? VNClassificationObservation {
            DispatchQueue.main.async {
                self.hideEmotionLabels(hide: false)
                self.emotionIdentifierLabel.text = "\(emotionObservation.identifier)"
                self.emotionConfidenceLabel.text = "\(String(format: "%.1f", emotionObservation.confidence * 100))%"
                print("emotion : \(emotionObservation.identifier), confidence : \(emotionObservation.confidence)")
            }
        }
    }
    
    func hideAllLabels() {
        hideGenderLabels(hide: true)
        hideAgeLabels(hide: true)
        hideEmotionLabels(hide: true)
    }
    
    func hideGenderLabels(hide isHidden: Bool) {
        self.genderLabel.isHidden = isHidden
        self.genderIdentifierLabel.isHidden = isHidden
        self.genderConfidenceLabel.isHidden = isHidden
    }
    
    func hideAgeLabels(hide isHidden: Bool) {
        self.ageLabel.isHidden = isHidden
        self.ageIdentifierLabel.isHidden = isHidden
        self.ageConfidenceLabel.isHidden = isHidden
    }
    
    func hideEmotionLabels(hide isHidden: Bool) {
        self.emotionLabel.isHidden = isHidden
        self.emotionIdentifierLabel.isHidden = isHidden
        self.emotionConfidenceLabel.isHidden = isHidden
    }
    
    /** 얼굴에 표시된 빨간 사각형을 제거 함 */
    func removeRectangles() {
        if let sublayers = self.selectedImageView.layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
    }
    
    func removeFaceImageView() {
        for faceImageView in self.faceImageViews {
            faceImageView.removeFromSuperview()
        }
    }
}
