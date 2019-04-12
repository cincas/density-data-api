//  Copyright © 2019 cincas. All rights reserved.

import DensityDataAPI

extension Grid: Datasource {}

extension DataPoint: DataUnit {}

extension DensityDataAPI: APIClient {
  var datasource: Datasource {
    return getGrid()
  }
  
  func data(at index: Int) -> Result<[DataUnit]?, APIError> {
    do {
      let dataUnits = try getData(index: UInt(index))
      return .success(dataUnits)
    } catch _ as DensityDataAPI.DataError {
      return .failed(.dataError)
    } catch {
      return .failed(.unknown(error))
    }
  }
}

struct TestGrid: Datasource {
  let columns: UInt
  let rows: UInt
  let dataSize: UInt
}

struct TestDataPoint: DataUnit {
  let x: UInt
  let y: UInt
}

struct TestAPI: APIClient {
  let datasource: Datasource = TestGrid(columns: 3, rows: 3, dataSize: 3)
  let dataSet: [[DataUnit]?] = [
    [TestDataPoint(x: 0, y: 0)],
    [TestDataPoint(x: 1, y: 2), TestDataPoint(x: 2, y: 1)],
    [TestDataPoint(x: 0, y: 0)]
  ]
  
  func data(at index: Int) -> Result<[DataUnit]?, APIError> {
    return .success(dataSet[index])
  }
}
