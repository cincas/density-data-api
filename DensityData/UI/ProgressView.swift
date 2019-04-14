//  Copyright © 2019 cincas. All rights reserved.

import UIKit

class ProgressView: UIProgressView {
  private let statusLabel: UILabel = {
    let view = UILabel()
    view.textAlignment = .center
    return view
  }()
  
  var status: String? {
    get { return statusLabel.text }
    set { statusLabel.text = newValue }
  }
  
  var statusTextColor: UIColor? {
    get { return statusLabel.textColor }
    set { statusLabel.textColor = newValue }
  }
  
  override var progress: Float {
    didSet {
      statusLabel.text = "\(round(progress * 100))%"
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    prepare()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func prepare() {
    addSubview(statusLabel)
    statusLabel.pinEdges(to: self)
  }
}
