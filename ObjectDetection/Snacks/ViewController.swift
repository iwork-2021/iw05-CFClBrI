/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import CoreMedia
import CoreML
import UIKit
import Vision

class ViewController: UIViewController {

  @IBOutlet var videoPreview: UIView!

  var videoCapture: VideoCapture!
  var currentBuffer: CVPixelBuffer?

  lazy var visionModel: VNCoreMLModel = {
    do {
//        let coreMLWrapper = SnackLocalizationModel()
      let coreMLWrapper = SnackDetector()
      let visionModel = try VNCoreMLModel(for: coreMLWrapper.model)

      if #available(iOS 13.0, *) {
        visionModel.inputImageFeatureName = "image"
        visionModel.featureProvider = try MLDictionaryFeatureProvider(dictionary: [
          "iouThreshold": MLFeatureValue(double: 0.45),
          "confidenceThreshold": MLFeatureValue(double: 0.25),
        ])
      }

      return visionModel
    } catch {
      fatalError("Failed to create VNCoreMLModel: \(error)")
    }
  }()

  lazy var visionRequest: VNCoreMLRequest = {
    let request = VNCoreMLRequest(model: visionModel, completionHandler: {
      [weak self] request, error in
      self?.processObservations(for: request, error: error)
    })

    // NOTE: If you choose another crop/scale option, then you must also
    // change how the BoundingBoxView objects get scaled when they are drawn.
    // Currently they assume the full input image is used.
    request.imageCropAndScaleOption = .scaleFill
    return request
  }()

  let maxBoundingBoxViews = 10
  var boundingBoxViews = [BoundingBoxView]()
  var colors: [String: UIColor] = [:]

  override func viewDidLoad() {
    super.viewDidLoad()
    setUpBoundingBoxViews()
    setUpCamera()
  }

  func setUpBoundingBoxViews() {
    for _ in 0..<maxBoundingBoxViews {
      boundingBoxViews.append(BoundingBoxView())
    }

    let labels = [
      "apple",
      "banana",
      "cake",
      "candy",
      "carrot",
      "cookie",
      "doughnut",
      "grape",
      "hot dog",
      "ice cream",
      "juice",
      "muffin",
      "orange",
      "pineapple",
      "popcorn",
      "pretzel",
      "salad",
      "strawberry",
      "waffle",
      "watermelon",
    ]

    // Make colors for the bounding boxes. There is one color for
    // each class, 20 classes in total.
    var i = 0
    for r: CGFloat in [0.5, 0.6, 0.75, 0.8, 1.0] {
      for g: CGFloat in [0.5, 0.8] {
        for b: CGFloat in [0.5, 0.8] {
          colors[labels[i]] = UIColor(red: r, green: g, blue: b, alpha: 1)
          i += 1
        }
      }
    }
  }

  func setUpCamera() {
    videoCapture = VideoCapture()
    videoCapture.delegate = self

    // Change this line to limit how often the video capture delegate gets
    // called. 1 means it is called 30 times per second, which gives realtime
    // results but also uses more battery power.
    videoCapture.frameInterval = 1

    videoCapture.setUp(sessionPreset: .hd1280x720) { success in
      if success {
        // Add the video preview into the UI.
        if let previewLayer = self.videoCapture.previewLayer {
          self.videoPreview.layer.addSublayer(previewLayer)
          self.resizePreviewLayer()
        }

        // Add the bounding box layers to the UI, on top of the video preview.
        for box in self.boundingBoxViews {
          box.addToLayer(self.videoPreview.layer)
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
    videoCapture.previewLayer?.frame = videoPreview.bounds
  }

  func predict(sampleBuffer: CMSampleBuffer) {
    if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
      currentBuffer = pixelBuffer

      // Get additional info from the camera.
      var options: [VNImageOption : Any] = [:]
      if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
        options[.cameraIntrinsics] = cameraIntrinsicMatrix
      }
        
      let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: options)
      do {
        try handler.perform([self.visionRequest])
      } catch {
        print("Failed to perform Vision request: \(error)")
      }
      currentBuffer = nil
    }
  }

  func processObservations(for request: VNRequest, error: Error?) {
    //call show function
      if error != nil {
          print(error!)
          return
      }
      let results = request.results
      var predictions : [VNRecognizedObjectObservation] = []
      if results != nil {
          for result in results! {
              predictions.append(result as! VNRecognizedObjectObservation)
          }
          self.show(predictions: predictions)
      }
  }

  func show(predictions: [VNRecognizedObjectObservation]) {
   //process the results, call show function in BoundingBoxView
      let num = min(predictions.count, self.maxBoundingBoxViews)
      DispatchQueue.main.sync(execute: {
          for i in 0 ..< num {
              let prediction: VNRecognizedObjectObservation = predictions[i]
              let boundingBox: CGRect = prediction.boundingBox
              let labels = prediction.labels
              let label = labels[0].identifier
              let confidence: Float = labels[0].confidence * 100
              let color: UIColor? = self.colors[label]
              let screenBounds: CGRect = UIScreen.main.bounds
              let screenWidth: CGFloat = screenBounds.width 
              let screenHeight: CGFloat = screenBounds.height
              let frame: CGRect = CGRect(x: boundingBox.minX * screenWidth,
                                                          y: boundingBox.minY * screenHeight,
                                                          width: boundingBox.width * screenWidth,
                                                          height: boundingBox.height * screenHeight)
              if color != nil {
                  self.boundingBoxViews[i].show(frame: frame, label: label + ":" + String(confidence) + "%", color: color!)
              }
              else {
                  print("Error: no match color for label " + label)
              }
          }
          
      })
      
      usleep(400000)
      
      DispatchQueue.main.sync(execute: {
          for i in 0 ..< num {
              self.boundingBoxViews[i].hide()
          }
      })
      
  }
}
    
extension ViewController: VideoCaptureDelegate {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
    predict(sampleBuffer: sampleBuffer)
  }
}
