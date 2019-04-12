//  Copyright © 2019 cincas. All rights reserved.

import UIKit

class GridView: UIView {
  private var viewModel: DataGridViewModel?
  private var ratioConstraint: NSLayoutConstraint?
  
  deinit {
    viewModel = nil
  }
  
  func apply(viewModel: DataGridViewModel) {
    self.viewModel = viewModel
    redraw()
  }
  
  func indexChanged(to index: Int) {
    guard let viewModel = viewModel else { return }
    let result = viewModel.getData(at: index)
    print("""
      Index: \(index)
      Current data: \(result)
      """)
  }
  
  private func redraw() {
    // Redraw grid graph
    let ratio: CGFloat = {
      guard let viewModel = self.viewModel else { return 1.0 }
      return CGFloat(viewModel.datasource.rows) / CGFloat(viewModel.datasource.columns)
    }()
    
    if let constraint = ratioConstraint {
      constraint.isActive = false
      removeConstraint(constraint)
    }
    ratioConstraint = heightAnchor.constraint(equalTo: widthAnchor, multiplier: ratio)
    ratioConstraint?.isActive = true
    setNeedsUpdateConstraints()
  }
}
