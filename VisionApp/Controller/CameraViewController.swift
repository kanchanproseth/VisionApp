//
//  ViewController.swift
//  VisionApp
//
//  Created by kanchanproseth on 12/1/17.
//  Copyright © 2017 Norton. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision
enum FlashState{
    case off
    case on
}

class CameraViewController: UIViewController {
    
    var photoData: Data?
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var flashControlState: FlashState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var roundedShadowView: RoundedShadowView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var ItemImage: RoundedShadowImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        spinner.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTabCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input){
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput){
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
            
            
        }catch{
            debugPrint(error)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func FlashButtonSelected(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashButton.setTitle("  Flash On  ", for: .normal)
            flashControlState = .on
            
        case .on:
            flashButton.setTitle("  Flash Off  ", for: .normal)
            flashControlState = .off
        }
        
    }
    
    @objc func didTabCameraView(){
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        let setitings = AVCapturePhotoSettings()
        
//        let previewPixelType = setitings.availablePreviewPhotoPixelFormatTypes.first!
//        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
//        setitings.previewPhotoFormat = previewFormat
        
        //Note the few code can run the same as this one line
        setitings.previewPhotoFormat = setitings.embeddedThumbnailPhotoFormat
        
        if flashControlState == .off{
            setitings.flashMode = .off
        }else{
            setitings.flashMode = .on
        }
        cameraOutput.capturePhoto(with: setitings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest,error: Error?){
        guard let results = request.results as? [VNClassificationObservation] else{ return }
        
        for classification in results{
            if classification.confidence < 0.5{
                let UnknownObjectMessage = "I am not sure what this is. please try again"
                self.itemName.text = UnknownObjectMessage
                synthesizerSpeech(fromString: UnknownObjectMessage)
                break
            }else{
                let identifier = classification.identifier
                self.itemName.text = identifier
                let completeMessage = "This look like a \(identifier)"
                synthesizerSpeech(fromString: completeMessage)
                break
            }
            
        }
    }
    
    func synthesizerSpeech(fromString string: String){
        let speachUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speachUtterance)
    }
    

}

extension CameraViewController: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            do{
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            }catch{
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.ItemImage.image = image
        }
    }
}

extension CameraViewController: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //code to finish utterance
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.startAnimating()
        self.spinner.isHidden = true
        
    }
}
