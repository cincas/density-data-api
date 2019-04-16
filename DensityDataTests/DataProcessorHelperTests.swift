//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData

class DataProcessorHelperTests: XCTestCase {
  func testProcessDataSet() {
    let dataSet: [[DataUnit]?] = [
      [MockDataUnit(x: 0, y: 0)],
      [MockDataUnit(x: 1, y: 1), MockDataUnit(x: 0, y: 2), MockDataUnit(x: 0, y: 1)],
      [ExceptionDataUnit(isAccepted: true)],
      [MockDataUnit(x: 1, y: 0), MockDataUnit(x: 1, y: 2), MockDataUnit(x: 0, y: 0)],
      nil,
      [MockDataUnit(x: 2, y: 1), MockDataUnit(x: 0, y: 0)],
      [MockDataUnit(x: 2, y: 0), MockDataUnit(x: 0, y: 0)]
    ]
    let flattened = Array(dataSet.compactMap { $0 }.joined())
    let result = DataProcessorHelper.process(dataSet: flattened)
    
    let expected = [
      DataUnitContainer(x: 0, y: 0): 4,
      DataUnitContainer(x: 0, y: 1): 1,
      DataUnitContainer(x: 0, y: 2): 1,
      DataUnitContainer(x: 1, y: 0): 1,
      DataUnitContainer(x: 1, y: 1): 1,
      DataUnitContainer(x: 2, y: 0): 1,
      DataUnitContainer(x: 2, y: 1): 1,
      DataUnitContainer(x: 2, y: 2): 0
    ]
    
    expected.forEach { unit in
      guard let actual = result[unit.key] else {
        XCTAssert(unit.value == 0)
        return
      }
      
      XCTAssertEqual(actual, unit.value, "\(result)\n\(flattened)")
    }
  }
}
