//
//  FaceDetectionViewController.swift
//  ARFaceDetection
//
//  Created by Ioannis Pasmatzis on 12/12/17.
//  Copyright © 2017 Yanniki. All rights reserved.
//

import UIKit
import ARKit
import Vision

class FaceDetectionViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    private var scanTimer: Timer?
    
    private var scannedFaceViews = [UIView]()
    
    //get the orientation of the image that correspond's to the current device orientation
    private var imageOrientation: CGImagePropertyOrientation {
        switch UIDevice.current.orientation {
        case .portrait: return .right
        case .landscapeRight: return .down
        case .portraitUpsideDown: return .left
        case .unknown: fallthrough
        case .faceUp: fallthrough
        case .faceDown: fallthrough
        case .landscapeLeft: return .up
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        //scan for faces in regular intervals
        scanTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(scanForFaces), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        scanTimer?.invalidate()
        sceneView.session.pause()
    }
    
    @objc
    private func scanForFaces() {
        
        //remove the test views and empty the array that was keeping a reference to them
        _ = scannedFaceViews.map { $0.removeFromSuperview() }
        scannedFaceViews.removeAll()
        
        //get the captured image of the ARSession's current frame
        guard let capturedImage = sceneView.session.currentFrame?.capturedImage else { return }
        
        let image = CIImage.init(cvPixelBuffer: capturedImage)
        
        let cageImage = UIImage(named: "nick-cage-take2.png")
        
        let detectFaceRequest = VNDetectFaceRectanglesRequest { (request, error) in
            
            DispatchQueue.main.async {
                //Loop through the resulting faces and add a red UIView on top of them.
                if let faces = request.results as? [VNFaceObservation] {
                    for face in faces {
                        let faceFrame = self.faceFrame(from: face.boundingBox)
                        let imageView = UIImageView()
                        imageView.frame = faceFrame
                        imageView.image = cageImage
                        imageView.center = UIView(frame: faceFrame).center
                        
                        self.sceneView.addSubview(imageView)
                        
                        self.scannedFaceViews.append(imageView)
                    }
                }
            }
        }
        
        DispatchQueue.global().async {
            try? VNImageRequestHandler(ciImage: image, orientation: self.imageOrientation).perform([detectFaceRequest])
        }
    }
    
    private func faceFrame(from boundingBox: CGRect) -> CGRect {
        
        let scale = CGFloat(2.5)
        
        //translate camera frame to frame inside the ARSKView
        let unscaledWidth = boundingBox.width * sceneView.bounds.width;
        let unscaledHeight = boundingBox.height * sceneView.bounds.height;
        
        let size = CGSize(width: unscaledWidth*scale, height: unscaledHeight*scale)
        let ox0 = boundingBox.minX*sceneView.bounds.width
        let oy0 = (1-boundingBox.maxY)*sceneView.bounds.height
        let ox1 = ox0 - (unscaledWidth*(scale-1))/2
        let oy1 = oy0 - (unscaledHeight*(scale-1))/2
        
        let origin = CGPoint(x: ox1, y: oy1)
        
        return CGRect(origin: origin, size: size)
    }
}

extension FaceDetectionViewController: ARSCNViewDelegate {
    //implement ARSCNViewDelegate functions for things like error tracking
}
