import UIKit

extension CIImage {
  var cvPixelBuffer: CVPixelBuffer? {
    let attrs = [
                  kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                  kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
                  kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue
                ] as CFDictionary

    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     Int(self.extent.width),
                                     Int(self.extent.height),
                                     kCVPixelFormatType_32BGRA,
                                     attrs,
                                     &pixelBuffer)

    guard status == kCVReturnSuccess else {
      return nil
    }

    guard let buffer = pixelBuffer else {
      return nil
    }

    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.init(rawValue: 0))

    let context = CIContext()
    context.render(self, to: buffer)

    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    return pixelBuffer
  }
}
