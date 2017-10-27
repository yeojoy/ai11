//
//  ObjectDetectionViewController.swift
//  ai11
//
//  Created by Yeojong Kim on 2017. 10. 26..
//  Copyright © 2017년 Yeojong Kim. All rights reserved.
//

import UIKit
import Vision

class ObjectDetectionViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var selectedImage: UIImage? {
        didSet {
            self.selectedImageView.image = selectedImage
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicatorView.stopAnimating()
        self.nameLabel.text = ""
        self.confidenceLabel.text = ""
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addPhoto(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let importFromAlbum = UIAlertAction(title: "앨범에서 가져오기", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        }
        
        let takePhoto = UIAlertAction(title: "카메라로 찍기", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = true
            picker.cameraCaptureMode = .photo
        
            self.present(picker, animated: true, completion: nil)
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        actionSheet.addAction(importFromAlbum)
        actionSheet.addAction(takePhoto)
        actionSheet.addAction(cancel)
            
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        if let uiImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.selectedImage = uiImage
            detectObject()
        }
    }
    
    func detectObject() {
        // 모델이 이미지를 넣어서 계산
        if let ciImage = self.selectedCIImage {
            self.activityIndicatorView.startAnimating()
            self.nameLabel.text = ""
            self.confidenceLabel.text = ""
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let vnCoreMLModel = try VNCoreMLModel(for: Inceptionv3().model)
                    let request = VNCoreMLRequest(model: vnCoreMLModel, completionHandler: self.handleObjectDetection)
                    request.imageCropAndScaleOption = .centerCrop
                    let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                    try requestHandler.perform([request])
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func handleObjectDetection(_ request: VNRequest, _ error: Error?) {
        if let results = request.results as? [VNClassificationObservation] {
            print("=======================================================================")
            for result in results {
                print("\(result.identifier) : \(result.confidence)")
            }
            
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                let result = results.first!
                self.nameLabel.text = result.identifier
                self.confidenceLabel.text = "\(String(format: "%.1f", result.confidence * 100))%"
            }
            print("=======================================================================")
        }
    }
}
