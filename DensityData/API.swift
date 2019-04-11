//  Copyright © 2019 cincas. All rights reserved.

import DensityDataAPI

protocol APIClient {
  func getDataSource() -> DataSource
  func data(at index: UInt) throws -> [DataUnit]?
}

protocol DataSource {
  var columns: UInt { get }
  var rows: UInt { get }
  var dataSize: UInt { get }
}

protocol DataUnit {
  var x: UInt { get }
  var y: UInt { get }
}

extension Grid: DataSource {}
extension DataPoint: DataUnit {}
extension DensityDataAPI: APIClient {
  func getDataSource() -> DataSource {
    return getGrid()
  }
  
  func data(at index: UInt) throws -> [DataUnit]? {
    return try getData(index: index)
  }
}
