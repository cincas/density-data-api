//  Copyright © 2019 cincas. All rights reserved.

import UIKit
import DensityDataAPI

class ViewController: UIViewController {
  private let viewModel: DataGridViewModel
  init(viewModel: DataGridViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private let slider: UISlider = {
    let view = UISlider()
    // TODO: Implement continuous value change
    view.isContinuous = false
    return view
  }()
  
  private let gridView: GridView = {
    let view = GridView()
    view.backgroundColor = .black
    return view
  }()
  
  private let contentView: UIStackView = {
    let view = UIStackView()
    view.axis = .vertical
    view.distribution = .fill
    view.alignment = .fill
    view.isLayoutMarginsRelativeArrangement = true
    view.spacing = 8
    view.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
    return view
  }()
  
  private let datasourceInfoLabel: UILabel = {
    let view = UILabel()
    view.textColor = .black
    view.backgroundColor = .clear
    view.numberOfLines = 0
    return view
  }()
  
  override func loadView() {
    let view = UIView()
    view.backgroundColor = .white
    self.view = view
    
    let scrollView = UIScrollView()
    view.addSubview(scrollView)
    
    let containerView = UIView()
    containerView.addSubview(contentView)
    scrollView.addSubview(containerView)
    
    [datasourceInfoLabel, gridView, slider, UIView()].forEach { contentView.addArrangedSubview($0) }
    
    scrollView.pinEdges(to: view)
    containerView.pinEdges(to: scrollView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    gridView.translatesAutoresizingMaskIntoConstraints = false
    [
      containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 1.0),
      containerView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: contentView.bottomAnchor,
                                            multiplier: 1),
      containerView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),
      contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      contentView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor)
    ].forEach { $0.isActive = true }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = viewModel.title
    slider.addTarget(self, action: #selector(onSliderValueChanged(_:)), for: .valueChanged)
    let resetBarItem = UIBarButtonItem(title: "Reset", style: .plain,
                                       target: self, action: #selector(onResetTapped(_:)))
    navigationItem.leftBarButtonItem = resetBarItem
    viewModel.delegate = self
    applyDatasource(animated: false)
  }
  
  @objc private func onSliderValueChanged(_ sender: UISlider) {
    let index = Int(roundf(sender.value))
    gridView.indexChanged(to: index)
  }
  
  @objc private func onResetTapped(_ sender: UIBarButtonItem) {
    // TODO: Decouple DensityDataAPI from view controller
    viewModel.resetAPIClient(to: TestAPI())
    applyDatasource()
  }
  
  private func applyDatasource(animated: Bool = true) {
    viewModel.loadDatasource()
    slider.minimumValue = 0.0
    slider.maximumValue = Float(viewModel.datasource.dataSize)
    slider.value = 0.0
    datasourceInfoLabel.text = viewModel.datasourceInfo
    gridView.apply(viewModel: self.viewModel)
    if animated {
      UIView.animate(withDuration: 0.5) {
        self.view.layoutIfNeeded()
      }
    }
    
  }
}

extension ViewController: DataGridViewModelDelegate {
  func loadingStarted() {
    slider.isUserInteractionEnabled = false
  }
  
  func loadingCompleted() {
    slider.isUserInteractionEnabled = true
  }
  
  func loadingProgressUpdated(_ progress: CGFloat) {
    
  }
  
  func loadingFailedAt(_ index: Int) {
    
  }
  
}
