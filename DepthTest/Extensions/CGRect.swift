import UIKit

extension CGRect {
  func setOrigin () -> CGRect {
    var frame = self
    frame.origin = CGPoint.init(x: 0, y: 0)
    return frame
  }
}

extension CGRect {
  func setSize (height: CGFloat) -> CGRect {
    var frame = self
    frame.size = CGSize.init(width: frame.size.width, height: height)
    return frame
  }
  
  func setSize (width: CGFloat) -> CGRect {
    var frame = self
    frame.size = CGSize.init(width: width, height: frame.size.height)
    return frame
  }
}
