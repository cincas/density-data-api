//  Copyright © 2019 cincas. All rights reserved.

import Foundation
@testable import DensityData
import DensityDataAPI

struct MockAPIClient: APIClient {
  let datasource: Datasource
  private let dataSet: [[DataUnit]?]
  init(datasource: Datasource, dataSet: [[DataUnit]?]) {
    self.datasource = datasource
    self.dataSet = dataSet
  }
  
  func data(at index: Int) -> Result<[DataUnit]?, APIError> {
    let dataUnits = dataSet[index]
    
    if let exceptionDataUnit = (dataUnits?.compactMap { $0 as? ExceptionDataUnit }.first) {
      return exceptionDataUnit.isAccepted ? .failed(.dataError)
        : .failed(.unknown(NSError(domain: "com.cincas.api.error", code: 0, userInfo: nil)))
    }
    return .success(dataUnits)
  }
}

struct MockDatasource: Datasource {
  let columns: UInt
  let rows: UInt
  let dataSize: UInt
  init(columns: UInt, rows: UInt, dataSize: UInt) {
    self.columns = columns
    self.rows = rows
    self.dataSize = dataSize
  }
  
  static func random() -> MockDatasource {
    let rows = arc4random_uniform(10) + 1
    let columns = arc4random_uniform(10) + rows
    let dataSize = arc4random_uniform(10) + 1
    return MockDatasource(columns: UInt(columns),
                          rows: UInt(rows),
                          dataSize: UInt(dataSize))
  }
}

struct MockDataUnit: DataUnit {
  let x: UInt
  let y: UInt
  static func random(in datasource: MockDatasource) -> MockDataUnit {
    return random(maxX: datasource.columns, maxY: datasource.rows)
  }
  
  static func random(maxX: UInt, maxY: UInt) -> MockDataUnit {
    let x = UInt(arc4random_uniform(UInt32(maxX)))
    let y = UInt(arc4random_uniform(UInt32(maxY)))
    return MockDataUnit(x: x, y: y)
  }
}

struct ExceptionDataUnit: DataUnit {
  let x: UInt
  let y: UInt
  let isAccepted: Bool
  
  init(isAccepted: Bool) {
    self.isAccepted = isAccepted
    x = 0
    y = 0
  }
}
