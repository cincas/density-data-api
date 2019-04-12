//  Copyright © 2019 cincas. All rights reserved.

import UIKit

extension UIView {
  func pinEdges(to layoutGuide: UILayoutGuide) {
    translatesAutoresizingMaskIntoConstraints = false
    [
      leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor),
      trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor),
      topAnchor.constraint(equalTo: layoutGuide.topAnchor),
      bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor)]
      .forEach { $0.isActive = true }
  }
  
  func pinEdges(to view: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    [
      leadingAnchor.constraint(equalTo: view.leadingAnchor),
      trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topAnchor.constraint(equalTo: view.topAnchor),
      bottomAnchor.constraint(equalTo: view.bottomAnchor)]
      .forEach { $0.isActive = true }
  }
}
