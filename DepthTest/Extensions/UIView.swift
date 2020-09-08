import Foundation
import UIKit

extension UIView {
  private func traverseResponderChainForUIViewController () -> Any? {
    let nextResponder: UIResponder = self.next!
    if nextResponder is UIViewController {
      return nextResponder
    } else if nextResponder is UIView {
      return (nextResponder as! UIView).traverseResponderChainForUIViewController()
    } else {
      return nil
    }
  }

  func findClosestUIViewController () -> UIViewController? {
    guard let controller = self.traverseResponderChainForUIViewController() as? UIViewController else {
      return nil
    }
    return controller
  }
}

extension UIView {
  func verticalAlignViews (views: Array<UIView>, distance: CGFloat) -> Void {
    if views.count == 0 {
      return
    }

    var y: CGFloat = views.first!.frame.origin.y
    for view in views {
      if view.isHidden {
        continue
      }

      if y > view.frame.origin.y {
        y = view.frame.origin.y
      }
    }

    for view in views {
      if view.isHidden {
        continue
      }

      var frame = view.frame
      frame.origin.y = y
      view.frame = frame

      y += view.frame.size.height + distance
    }
  }
  
  func centerHorizontal (view: UIView) -> Void {
    var a = view.frame
    let b = self.frame
    a.origin.x = b.size.width / 2.0 - a.size.width / 2.0
    view.frame = a
  }
  
  func centerHorizontal (views: [UIView]) -> Void {
    for item in views {
      self.centerHorizontal(view: item)
    }
  }
  
  func resizeHeightToFitSubViews () -> Void {
    // Calculate required size
    var r = CGRect.zero
    for view in self.subviews {
      r = r.union(view.frame)
    }

    // Move all subviews inside
    let fix = r.origin
    for view in self.subviews {
      view.frame = view.frame.offsetBy(dx: -fix.x, dy: -fix.y)
    }

    // Move frame to negate the previous movement
    var newFrame = self.frame.offsetBy(dx: fix.x, dy: fix.y)
    newFrame.size.height = r.size.height

    self.frame = newFrame
  }
}
