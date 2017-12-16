//
//  TextDetectorViewcontroller.swift
//  VisionApp
//
//  Created by kanchanproseth on 12/2/17.
//  Copyright © 2017 Norton. All rights reserved.
//

import UIKit
import TesseractOCR

class TextDetectorViewcontroller: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var findTextField: UITextField!
    @IBOutlet weak var replaceTextField: UITextField!
    @IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // IBAction methods
    @IBAction func backgroundTapped(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func textFieldEndOnExit(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        view.endEditing(true)
        presentImagePicker()
    }
    
    @IBAction func swapText(_ sender: Any) {
        view.endEditing(true)
        
        guard let text = textView.text,
            let findText = findTextField.text,
            let replaceText = replaceTextField.text else {
                return
        }
        
        textView.text = text.replacingOccurrences(of: findText, with: replaceText)
        findTextField.text = nil
        replaceTextField.text = nil
    }
    
    @IBAction func sharePoem(_ sender: Any) {
        if textView.text.isEmpty {
            return
        }
        let activityViewController = UIActivityViewController(activityItems:
            [textView.text], applicationActivities: nil)
        let excludeActivities:[UIActivityType] = [
            .assignToContact,
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo]
        activityViewController.excludedActivityTypes = excludeActivities
        present(activityViewController, animated: true)
    }
    
    // Tesseract Image Recognition
    func performImageRecognition(_ image: UIImage) {
        
        if let tesseract = G8Tesseract(language: "eng+fra") {
            tesseract.engineMode = .tesseractCubeCombined
            tesseract.pageSegmentationMode = .auto
            tesseract.image = image.g8_blackAndWhite()
            tesseract.recognize()
            textView.text = tesseract.recognizedText
        }
        activityIndicator.stopAnimating()
    }
    
    // The following methods handle the keyboard resignation/
    // move the view so that the first responders aren't hidden
    func moveViewUp() {
        if topMarginConstraint.constant != 0 {
            return
        }
        topMarginConstraint.constant -= 135
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func moveViewDown() {
        if topMarginConstraint.constant == 0 {
            return
        }
        topMarginConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate
extension TextDetectorViewcontroller: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        moveViewUp()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        moveViewDown()
    }
}

// MARK: - UINavigationControllerDelegate
extension TextDetectorViewcontroller: UINavigationControllerDelegate {
}

// MARK: - UIImagePickerControllerDelegate
extension TextDetectorViewcontroller: UIImagePickerControllerDelegate {
    func presentImagePicker() {
        
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Image",
                                                       message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraButton = UIAlertAction(title: "Take Photo",
                                             style: .default) { (alert) -> Void in
                                                let imagePicker = UIImagePickerController()
                                                imagePicker.delegate = self
                                                imagePicker.sourceType = .camera
                                                self.present(imagePicker, animated: true)
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        let libraryButton = UIAlertAction(title: "Choose Existing",
                                          style: .default) { (alert) -> Void in
                                            let imagePicker = UIImagePickerController()
                                            imagePicker.delegate = self
                                            imagePicker.sourceType = .photoLibrary
                                            self.present(imagePicker, animated: true)
        }
        imagePickerActionSheet.addAction(libraryButton)
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
        imagePickerActionSheet.addAction(cancelButton)
        
        present(imagePickerActionSheet, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let selectedPhoto = info[UIImagePickerControllerOriginalImage] as? UIImage,
            let scaledImage = selectedPhoto.scaleImage(640) {
            
            activityIndicator.startAnimating()
            
            dismiss(animated: true, completion: {
                self.performImageRecognition(scaledImage)
            })
        }
    }
}

// MARK: - UIImage extension
extension UIImage {
    func scaleImage(_ maxDimension: CGFloat) -> UIImage? {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        if size.width > size.height {
            let scaleFactor = size.height / size.width
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            let scaleFactor = size.width / size.height
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}


