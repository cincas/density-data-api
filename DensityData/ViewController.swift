//  Copyright © 2019 cincas. All rights reserved.

import UIKit

class ViewController: UIViewController {
  private let viewModel: DataGridViewModel
  init(viewModel: DataGridViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
}
