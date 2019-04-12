//  Copyright © 2019 cincas. All rights reserved.

import UIKit

// Ideally, should use things like ReactiveSwift/RxSwift to do data binding
protocol DataGridViewModelDelegate: class {
  func loadingStarted()
  func loadingCompleted()
  
  /// Loading progress in percentage
  func loadingProgressUpdated(_ progress: CGFloat)
  
  func loadingFailedAt(_ index: Int)
}

class DataGridViewModel {
  private var apiClient: APIClient {
    didSet {
      datasource = apiClient.datasource
      processor?.stop()
      processor = DataProcessor(apiClient: apiClient)
      processor?.delegate = self
    }
  }
  
  private(set) var datasource: Datasource
  private var processor: DataProcessor?
  weak var delegate: DataGridViewModelDelegate?
  init(apiClient: APIClient) {
    self.apiClient = apiClient
    self.datasource = apiClient.datasource
    processor = DataProcessor(apiClient: apiClient)
    processor?.delegate = self
  }
  
  // MARK: - Layout values
  var datasourceInfo: String {
    return """
    Columns: \(datasource.columns)
    Rows: \(datasource.rows)
    Data size: \(datasource.dataSize)
    """
  }
  
  var title: String {
    return "Density Data Graph"
  }
  
  // MARK: - Actions
  func loadDatasource() {
    delegate?.loadingStarted()
    processor?.stop()
    processor?.start { [weak self] result in
      print("receive data: \(result.count)")
      self?.delegate?.loadingCompleted()
    }
  }

  func resetAPIClient(to newAPIClient: APIClient) {
    apiClient = newAPIClient
  }
  
  func getData(at index: Int) -> Result<[DataUnit]?, APIError> {
    return apiClient.data(at: index)
  }
}

extension DataGridViewModel: DataProcessorDelegate {
  func progressUpdated(_ progress: Int) {
    print("Finish processing: \(progress)")
    let percentage = CGFloat(progress + 1) / CGFloat(datasource.dataSize)
    delegate?.loadingProgressUpdated(percentage)
  }
  
  func processFailed(at index: Int) {
    // TODO: Collect errors at these points
    print("Failed getting data at \(index)")
    delegate?.loadingFailedAt(index)
  }
}
