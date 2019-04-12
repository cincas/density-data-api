//  Copyright © 2019 cincas. All rights reserved.

import UIKit

class GridView: UIView {
  private var viewModel: DataGridViewModel?
  private var ratioConstraint: NSLayoutConstraint?
  private var gridLayer: GridLayer? {
    return layer.sublayers?.compactMap { $0 as? GridLayer }.first
  }
  
  private var currentIndex: Int = 0
  var shouldRedraw: Bool = false
  deinit {
    viewModel = nil
  }
  
  func apply(viewModel: DataGridViewModel) {
    self.viewModel = viewModel
    updateViewSize()
  }
  
  func indexChanged(to index: Int) {
    currentIndex = index
    guard let result = viewModel?.snapshot(at: index) else { return }
    gridLayer?.update(by: result)
  }

  func drawGrid() {
    guard let viewModel = viewModel else { return }
    let gridLayer = GridLayer(columns: Int(viewModel.datasource.columns),
                              rows: Int(viewModel.datasource.rows))
    layer.addSublayer(gridLayer)
    gridLayer.frame = bounds
    gridLayer.drawGrid()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if shouldRedraw {
      redraw()
      shouldRedraw = false
    }
  }
  
  private func redraw() {
    updateViewSize()
    drawGrid()
    indexChanged(to: currentIndex)
  }
  
  private func updateViewSize() {
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
    gridLayer?.removeFromSuperlayer()
  }

}

class GridLayer: CAShapeLayer {
  private let columns: Int
  private let rows: Int
  private var tileMap: [IndexPath: CAShapeLayer] = [:]
  init(columns: Int, rows: Int) {
    self.columns = columns
    self.rows = rows
    super.init()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func drawGrid() {
    let rows = CGFloat(self.rows)
    let columns = CGFloat(self.columns)
    let tileWidth = bounds.width / columns
    let tileSize = CGSize(width: tileWidth, height: tileWidth)
    func makeLayer(_ rect: CGRect) -> CAShapeLayer {
      let layer = CAShapeLayer()
      layer.frame = rect
      layer.backgroundColor = UIColor.green.cgColor
      return layer
    }
    
    let tiles = (0..<Int(rows)).map { row -> [CAShapeLayer]  in
      return (0..<Int(columns)).map { column -> CAShapeLayer in
        let indexPath = IndexPath(item: column, section: row)
        let layer = makeLayer(CGRect(x: CGFloat(column) * tileWidth, y: CGFloat(row) * tileWidth,
                                     width: tileWidth, height: tileWidth))
        tileMap[indexPath] = layer
        return layer
      }
    }.joined()
    
    Array(tiles).forEach { addSublayer($0) }
  }
  
  func update(by snapshot: DatasourceSnapshot) {
    let appearanceResults = snapshot.appearanceResults
    tileMap.forEach { index, layer in
      guard let unit = (appearanceResults.keys.first { $0.x == index.item && $0.y == index.section }),
        let value = appearanceResults[unit] else {
        layer.opacity = 0.0
        return
      }
      layer.opacity = value
    }
  }
}
