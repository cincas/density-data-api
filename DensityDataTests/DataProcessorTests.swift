//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData
import DensityDataAPI

// FIXME: Need to improve performance of DataProcessor
class DataProcessorTests: XCTestCase {
  func testDensityDataPerformance() {
    let processor = DataProcessor(apiClient: DensityDataAPI())
    let expectation = self.expectation(description: NSUUID().uuidString)
    measure {
      processor.start { _ in
        expectation.fulfill()
      }
    }
    wait(for: [expectation], timeout: 30.0)
  }

  func testMockAPIClientPerformance() {
    let datasource = MockDatasource(columns: 100, rows: 100, dataSize: 10000)
    let dataSet: [[DataUnit]?] = (0..<Int(datasource.dataSize)).map { _ in
      makeDataEntry(in: datasource)
    }
    let processor = DataProcessor(apiClient: MockAPIClient(datasource: datasource, dataSet: dataSet))
    
    let expectation = self.expectation(description: NSUUID().uuidString)
    measure {
      processor.start { _ in
        expectation.fulfill()
      }
      
    }
    wait(for: [expectation], timeout: 30.0)
  }
  
  private func makeDataEntry(in datasource: MockDatasource) -> [DataUnit]? {
    let numberOfUnits = Int.random(in: 1...50)
    return (0..<numberOfUnits).map { _ in MockDataUnit.random(in: datasource) }
  }
}
