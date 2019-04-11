//  Copyright © 2019 cincas. All rights reserved.

import Foundation

struct DataGridViewModel {
  private let apiClient: APIClient
  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }
  
  func getDataSource() -> DataSource {
    return apiClient.getDataSource()
  }
  
  func data(at index: UInt) throws -> [DataUnit]? {
    return try apiClient.data(at: index)
  }
}
