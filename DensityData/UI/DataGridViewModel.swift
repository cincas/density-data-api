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
  func resetAPIClient(to newAPIClient: APIClient) {
    apiClient = newAPIClient  
  }
  
  func getData(at index: Int) -> Result<[DataUnit]?, APIError> {
    return apiClient.data(at: index)
  }
}
