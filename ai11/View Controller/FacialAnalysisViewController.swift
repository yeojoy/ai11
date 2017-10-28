//
//  FacialAnalysisViewController.swift
//  ai11
//
//  Created by Yeojong Kim on 2017. 10. 26..
//  Copyright © 2017년 Yeojong Kim. All rights reserved.
//

import UIKit

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
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingActivityIndicatorView.stopAnimating()
        
        // Do any additional setup after loading the view.
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
            DispatchQueue.global(qos: .userInitiated).async {
                self.detectFaces()
            }
        }
    }

    func detectFaces() {
        
    }
}
