import UIKit

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let view = UIPresentView(frame:self.view.bounds)
    self.view.addSubview(view)
  }
}
