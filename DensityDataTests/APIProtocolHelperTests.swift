//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData
import DensityDataAPI

class APIProtocolHelperTests: XCTestCase {
  func testEqual() {
    let dataUnitA = MockDataUnit(x: 0, y: 0)
    let dataUnitB = MockDataUnit(x: 0, y: 0)
    XCTAssertTrue(dataUnitA == dataUnitB)
  }
  
  func testNotEqual() {
    let dataUnitA = MockDataUnit(x: 0, y: 0)
    let dataUnitB = MockDataUnit(x: 0, y: 1)
    XCTAssertFalse(dataUnitA == dataUnitB)
  }
  
  func testDensityDataAPI() {
    let densityAPI = DensityDataAPI()
    let expectedDatasource = densityAPI.datasource
    let actualDatasource = densityAPI.getGrid()
    XCTAssertTrue(expectedDatasource.columns == actualDatasource.columns)
    XCTAssertTrue(expectedDatasource.rows == actualDatasource.rows)
    XCTAssertTrue(expectedDatasource.dataSize == actualDatasource.dataSize)
    // Remember to test exception
    let actualData = densityAPI.data(at: 0)
    
    do {
      let expectedData = try densityAPI.getData(index: 0)
      
      switch actualData {
      case let .success(value):
        let actualValue = value as? [DataPoint]
        XCTAssertTrue(actualValue == expectedData)
      case let .failed(error):
        XCTFail("Unknown error: \(error)")
        break
      }
      
    } catch _ as DensityDataAPI.DataError {
      guard case let .failed(error) = actualData, case .dataError = error else {
        XCTFail("Incorrect data error")
        return
      }
    } catch {
      XCTFail("Unknown exception: \(error)")
    }
  }
}
