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
    view.isContinuous = true
    return view
  }()
  
  private let gridView: GridView = {
    let view = GridView()
    view.backgroundColor = .white
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
  
  private let progressView: UIProgressView = {
    let view = UIProgressView(progressViewStyle: .bar)
    view.backgroundColor = .red
    view.tintColor = .blue
    return view
  }()
  
  private let indexLabel: UILabel = {
    let view = UILabel()
    view.textColor = .black
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
    
    [datasourceInfoLabel,
     progressView,
     gridView,
     slider, indexLabel,
     UIView()]
      .forEach { contentView.addArrangedSubview($0) }
    
    scrollView.pinEdges(to: view.readableContentGuide)
    containerView.pinEdges(to: scrollView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    gridView.translatesAutoresizingMaskIntoConstraints = false
    progressView.translatesAutoresizingMaskIntoConstraints = false
    [
      containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 1.0),
      containerView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: contentView.bottomAnchor,
                                            multiplier: 1),
      containerView.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),
      contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      contentView.topAnchor.constraint(equalTo: containerView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      contentView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),
      progressView.heightAnchor.constraint(equalToConstant: 35),
      progressView.widthAnchor.constraint(equalTo: slider.widthAnchor)
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
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    gridView.shouldRedraw = true
  }
  
  @objc private func onSliderValueChanged(_ sender: UISlider) {
    let index = Int(roundf(sender.value))
    onIndexChanged(to: index)
  }
  
  private func onIndexChanged(to index: Int) {
    gridView.indexChanged(to: index)
    indexLabel.text = "Current index: \(index + 1)"
  }
  
  @objc private func onResetTapped(_ sender: UIBarButtonItem) {
    // TODO: Decouple DensityDataAPI from view controller
    viewModel.resetAPIClient(to: DensityDataAPI())
    applyDatasource()
  }
  
  private func applyDatasource(animated: Bool = true) {
    viewModel.loadDatasource()
    slider.minimumValue = 0.0
    slider.maximumValue = Float(viewModel.datasource.dataSize - 1)
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
    DispatchQueue.main.async {
      self.slider.isHidden = true
      self.indexLabel.isHidden = true
      self.progressView.progress = 0.0
    }
  }
  
  func loadingCompleted(_ configuration: DatasourceConfiguration) {
    DispatchQueue.main.async {
      self.slider.isHidden = false
      self.indexLabel.isHidden = false
      self.gridView.drawGrid()
      self.onIndexChanged(to: 0)
    }
  }
  
  func loadingProgressUpdated(_ progress: CGFloat) {
    DispatchQueue.main.async {
      self.progressView.progress = Float(progress)
    }
    
  }
  
  func loadingFailedAt(_ index: Int) {
    
  }
}
