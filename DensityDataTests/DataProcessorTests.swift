//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData
import DensityDataAPI

class DataProcessorTests: XCTestCase {
  func testSnapshot() {
    let dataSet: [[DataUnit]?] = [
      [MockDataUnit(x: 0, y: 0)],
      [MockDataUnit(x: 1, y: 1), MockDataUnit(x: 0, y: 2), MockDataUnit(x: 0, y: 1)],
      [ExceptionDataUnit(isAccepted: true)],
      [MockDataUnit(x: 1, y: 0), MockDataUnit(x: 1, y: 2), MockDataUnit(x: 0, y: 0)],
      nil,
      [MockDataUnit(x: 2, y: 1), MockDataUnit(x: 0, y: 0)],
      [MockDataUnit(x: 2, y: 0), MockDataUnit(x: 0, y: 0)]
    ]
    
    let expectedResults: [Int: AppearanceResults] = [
      2: [
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 0)): 0.25,
      ],
      3: [
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 0)): 0.5,
      ],
      4: [
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 0)): 0.5,
      ],
      5: [
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 0)): 0.75,
      ],
      6: [
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 0)): 1.0,
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 1)): 0.25,
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 2)): 0.25,
        DataUnitContainer(dataUnit: MockDataUnit(x: 1, y: 0)): 0.25,
        DataUnitContainer(dataUnit: MockDataUnit(x: 1, y: 1)): 0.25,
        DataUnitContainer(dataUnit: MockDataUnit(x: 1, y: 2)): 0.25,
        DataUnitContainer(dataUnit: MockDataUnit(x: 2, y: 1)): 0.25,
      ]
    ]
    
    let datasource = MockDatasource(columns: 3, rows: 3, dataSize: UInt(dataSet.count))
    let processor = DataProcessor(apiClient: MockAPIClient(datasource: datasource,
                                                           dataSet: dataSet))
    
    let loadExpectation = expectation(description: "Data set loading")
    processor.start { configuration in
      expectedResults.forEach { index, expected in
        guard let snapshot = configuration.snapshot(at: index) else {
          XCTFail("Snapshot should not be nil")
          return
        }
        self.assertAppearanceResult(expected, with: snapshot.appearanceResults)
      }
      loadExpectation.fulfill()
    }
    
    wait(for: [loadExpectation], timeout: 10.0)
  }
  
  private func assertAppearanceResult(_ expected: AppearanceResults, with actual: AppearanceResults) {
    expected.forEach { unit, value in
      guard let actual = actual[unit] else {
        XCTFail("Missing appearance result")
        return
      }
      XCTAssertTrue(value == actual,
                    "Appearance count should be same: \(unit.x, unit.y) \(value) : \(actual)")
    }
  }
}
