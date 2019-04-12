//  Copyright © 2019 cincas. All rights reserved.

import Foundation

class DataGridViewModel {
  private var apiClient: APIClient {
    didSet {
      datasource = apiClient.datasource
    }
  }
  
  private(set) var datasource: Datasource
  init(apiClient: APIClient) {
    self.apiClient = apiClient
    self.datasource = apiClient.datasource
    process(apiClient: apiClient)
  }
  
  // MARK: - Layout values
  var datasourceInfo: String {
    return """
    Columns: \(datasource.columns)
    Rows: \(datasource.rows)
    Data size: \(datasource.dataSize)
    """
  }
  
  // MARK: - Actions
  func process(apiClient: APIClient) {
    let processor = DataProcessor(apiClient: apiClient)
    processor.delegate = self
    processor.start { result in
      print("receive data: \(result.count)")
    }
  }
  
  func resetAPIClient(to newAPIClient: APIClient) {
    apiClient = newAPIClient
    process(apiClient: newAPIClient)
  }
  
  func getData(at index: Int) -> Result<[DataUnit]?, APIError> {
    return apiClient.data(at: index)
  }
}

extension DataGridViewModel: DataProcessorDelegate {
  func progressUpdated(_ progress: Int) {
    print("Finish processing: \(progress)")
  }
  
  func processFailed(at index: Int) {
    // TODO: Collect errors at these points
    print("Failed getting data at \(index)")
  }
}
