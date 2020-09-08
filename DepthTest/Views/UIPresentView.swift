import UIKit
import Foundation
import MobileCoreServices
import AVFoundation
import Vision

class UIPresentView: UIView {
  private var scroll:       UIScrollView!
  private var holder:       UIView!
  private let pickerController = UIImagePickerController()
  
  private let fcrnModel = FCRNFP16()
  private var request: VNCoreMLRequest?
  private var visionModel: VNCoreMLModel?
  
  private var originalImageSize:CGSize?
  
  override func didMoveToSuperview () {
    super.didMoveToSuperview()
    if self.superview == nil {
      return
    }

    self.build()
  }

  func build () -> Void {
    self.buildScrollView()
    self.buildHolder()
    self.startImageSelection()
  }
}

extension UIPresentView {
  private func buildScrollView () -> Void {
    let rect   = self.frame.setOrigin()
    let scroll = UIScrollView(frame: rect)
    scroll.alwaysBounceVertical = true
    scroll.alwaysBounceHorizontal = false
    scroll.showsHorizontalScrollIndicator = false
    scroll.showsVerticalScrollIndicator = false

    self.addSubview(scroll)
    self.scroll = scroll
  }
}

extension UIPresentView {
  private func buildHolder () -> Void {
    self.holder = UIView(frame: self.scroll.frame.setOrigin())
    self.holder.frame = self.holder.frame.setSize(height: 0)
    self.scroll.addSubview(self.holder)
  }
}

extension UIPresentView:UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
  func startImageSelection () -> Void {
    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
      let mediaTypes: [String] = [kUTTypeImage as String]

      self.pickerController.delegate = self
      self.pickerController.sourceType = .photoLibrary
      self.pickerController.allowsEditing = false
      self.pickerController.videoExportPreset = AVAssetExportPresetHighestQuality
      self.pickerController.mediaTypes = mediaTypes

      let controller = self.findClosestUIViewController()
      controller?.present(self.pickerController, animated: true, completion: nil)
    }
  }
  
  func imagePickerControllerDidCancel (_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
  }
  
  func imagePickerController (_ picker: UIImagePickerController,
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true)

    guard let found: UIImage = info[.originalImage] as? UIImage else {
      // Present user an error...
      return
    }
    
    let image   = found.orientationFix()!
    self.originalImageSize = image.size
    self.buildImageview(image)
    self.updateHolderContent()
    self.runEncoder(on: image)
  }
}

extension UIPresentView {
  private func buildImageview (_ image: UIImage) -> Void {
    let width  = self.holder.frame.size.width - 30
    let height = abs(image.size.height) * width / abs(image.size.width)
    let rect   = self.holder.bounds.setOrigin()
                                   .setSize(width: width)
                                   .setSize(height: height)
    let view   = UIImageView(image: image)
    view.frame = rect
    view.contentMode = .scaleAspectFit
    view.layer.cornerRadius = 6
    view.clipsToBounds = true

    self.holder.addSubview(view)
  }
  
  private func updateHolderContent () -> Void {
    self.holder.verticalAlignViews(views: self.holder.subviews, distance: 30 / 2.0)
    self.holder.centerHorizontal(views: self.holder.subviews)
    self.holder.resizeHeightToFitSubViews()

    self.scroll.contentSize = self.holder.frame.size
  }
  
  private func runEncoder (on image: UIImage) -> Void {
    let cgImage = image.cgImage!
    let options = [
      CIImageOption.applyOrientationProperty: true,
    ]

    let ciImage = CIImage(cgImage: cgImage, options: options)
    let imageBuffer = ciImage.cvPixelBuffer!
    
    self.visionModel = try! VNCoreMLModel(for: fcrnModel.model)
    self.request = VNCoreMLRequest(model: self.visionModel!,
                                   completionHandler: visionRequestDidComplete)
    self.request?.imageCropAndScaleOption = .scaleFill
    
    let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, options: [:])
    try! handler.perform([self.request!])
  }
  
  private func visionRequestDidComplete(request: VNRequest, error: Error?) {
    let observations = request.results as! [VNCoreMLFeatureValueObservation]
    let depthMap = observations.first!.featureValue.multiArrayValue!
    
    let depthMapW = depthMap.shape[1].intValue
    let depthMapH = depthMap.shape[2].intValue
    
    var converted: Array<Array<Double>> = Array(repeating: Array(repeating: 0.0,
                                                                 count: depthMapW),
                                                count: depthMapH)
    
    var minValue: Double = Double.greatestFiniteMagnitude
    var maxValue: Double = -Double.greatestFiniteMagnitude
    
    for i in 0 ..< depthMapW {
      for j in 0 ..< depthMapH {
        let index = i * (depthMapH) + j
        let confidence = depthMap[index].doubleValue
        guard confidence > 0 else { continue }
        converted[j][i] = confidence

        if minValue > confidence { minValue = confidence }
        if maxValue < confidence { maxValue = confidence }
      }
    }
    
    let gap = maxValue - minValue
    
    for i in 0 ..< depthMapW {
      for j in 0 ..< depthMapH {
          converted[j][i] = (converted[j][i] - minValue) / gap
      }
    }
    
    self.presentDepthMap(converted)
  }
}

extension UIPresentView {
  private func presentDepthMap(_ converted: Array<Array<Double>>) {
    let size = self.originalImageSize!
    let convertedW = converted.count
    let convertedH = converted.first!.count
    let w = size.width / CGFloat(convertedW)
    let h = size.height / CGFloat(convertedH)
    
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
    let context = UIGraphicsGetCurrentContext()!
    context.interpolationQuality = .high
    
    for j in 0 ..< convertedH {
        for i in 0 ..< convertedW {
            let value = converted[i][j]
            var alpha: CGFloat = CGFloat(value)
            if alpha > 1 {
                alpha = 1
            } else if alpha < 0 {
                alpha = 0
            }
            
            let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)
            let color: UIColor = UIColor(white: 1-alpha, alpha: 1)
            let bpath: UIBezierPath = UIBezierPath(rect: rect)
            
            color.set()
            bpath.fill()
        }
    }
    
    let result = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    let blurred = result.blur(radius: 6)
    self.buildImageview(blurred)
    self.updateHolderContent()
  }
}
