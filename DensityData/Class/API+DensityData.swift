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
  
  func mockDataSet() -> [[DataUnit]?] {
    return (0..<Int(dataSize)).map { _ in
      makeDataEntry(in: self)
    }
  }
  
  private func makeDataEntry(in datasource: TestGrid) -> [DataUnit]? {
    let numberOfUnits = Int.random(in: 1...50)
    return (0..<numberOfUnits).map { _ in TestDataPoint.random(in: datasource) }
  }
  
}

struct TestDataPoint: DataUnit {
  let x: UInt
  let y: UInt
  static func random(in datasource: Datasource) -> DataUnit {
    return random(maxX: datasource.columns, maxY: datasource.rows)
  }
  
  static func random(maxX: UInt, maxY: UInt) -> DataUnit {
    let x = UInt(arc4random_uniform(UInt32(maxX)))
    let y = UInt(arc4random_uniform(UInt32(maxY)))
    return TestDataPoint(x: x, y: y)
  }
}

struct TestAPI: APIClient {
  let dataSet: [[DataUnit]?]
  let datasource: Datasource
  
  init() {
    let testGrid = TestGrid(columns: 30, rows: 30, dataSize: 1000)
    datasource = testGrid
    dataSet = testGrid.mockDataSet()
  }
  
  func data(at index: Int) -> Result<[DataUnit]?, APIError> {
    return .success(dataSet[index])
  }
}
