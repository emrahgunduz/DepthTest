import UIKit

extension UIImage {
  func orientationFix () -> UIImage? {
    autoreleasepool { () -> UIImage? in
      guard self.imageOrientation != UIImage.Orientation.up else { return self.copy() as? UIImage }
      guard let cgImage = self.cgImage else { return nil }
      guard let colorSpace = cgImage.colorSpace else { return nil }

      let ctx = CGContext(data: nil,
                          width: Int(size.width),
                          height: Int(size.height),
                          bitsPerComponent: cgImage.bitsPerComponent,
                          bytesPerRow: 0,
                          space: colorSpace,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

      guard let context = ctx else { return nil }

      var transform: CGAffineTransform = CGAffineTransform.identity

      switch imageOrientation {
        case .down, .downMirrored:
          transform = transform.translatedBy(x: size.width, y: size.height)
          transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
          transform = transform.translatedBy(x: size.width, y: 0)
          transform = transform.rotated(by: CGFloat.pi / 2.0)
        case .right, .rightMirrored:
          transform = transform.translatedBy(x: 0, y: size.height)
          transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
          break
        @unknown default:
          break
      }

      // Flip image one more time if needed to, this is to prevent flipped image
      switch imageOrientation {
        case .upMirrored, .downMirrored:
          transform = transform.translatedBy(x: size.width, y: 0)
          transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
          transform = transform.translatedBy(x: size.height, y: 0)
          transform = transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
          break
        @unknown default:
          break
      }

      context.concatenate(transform)

      switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
          context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
          context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
          break
      }

      guard let newCGImage = context.makeImage() else { return nil }
      return UIImage.init(cgImage: newCGImage, scale: 1, orientation: .up)
    }
  }
}

extension UIImage {
 func scaled (to newSize: CGSize) -> UIImage {
   autoreleasepool { () -> UIImage in
    var scaledImageRect = CGRect.zero
     scaledImageRect.size.width = newSize.width
     scaledImageRect.size.height = newSize.height

     UIGraphicsBeginImageContext(newSize)
     let context = UIGraphicsGetCurrentContext()!
     context.interpolationQuality = .high

     self.draw(in: scaledImageRect)
     let scaledImage = UIGraphicsGetImageFromCurrentImageContext()

     UIGraphicsEndImageContext()

     return scaledImage!
   }
 }
}

// Blur
extension UIImage {
  func blur (radius: CGFloat) -> UIImage {
    let image         = self
    let currentFilter = CIFilter(name: "CIGaussianBlur")
    let beginImage    = CIImage(image: image)
    currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
    currentFilter!.setValue(radius, forKey: kCIInputRadiusKey)

    let cropFilter = CIFilter(name: "CICrop")
    cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
    cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")

    let context        = CIContext(options: nil)
    let output         = cropFilter!.outputImage
    let cgimg          = context.createCGImage(output!, from: output!.extent)
    let processedImage = UIImage(cgImage: cgimg!)
    return processedImage
  }
}
