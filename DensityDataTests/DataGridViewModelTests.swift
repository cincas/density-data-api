//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData

class DataGridViewModelTests: XCTestCase {
  func testReset() {
    let originalDatasource = MockDatasource(columns: 1, rows: 1, dataSize: 1)
    let viewModel = DataGridViewModel(apiClient: MockAPIClient(datasource: originalDatasource,
                                                               dataSet: []))
    let newDatasource = MockDatasource(columns: 2, rows: 2, dataSize: 2)
    viewModel.resetAPIClient(to: MockAPIClient(datasource: newDatasource,
                                               dataSet: []))
    
    XCTAssertTrue(isSame(lhs: viewModel.datasource, rhs: newDatasource))
  }
  
  func testGetDatasource() {
    let dataSource = MockDatasource(columns: 1, rows: 1, dataSize: 1)
    let viewModel = DataGridViewModel(apiClient: MockAPIClient(datasource: dataSource,
                                                               dataSet: []))
    XCTAssertTrue(isSame(lhs: viewModel.datasource, rhs: dataSource))
  }
  
  func testGetSnapshot() {
    let dataSet: [[DataUnit]?] = [
      [MockDataUnit(x: 0, y: 0)],
      [MockDataUnit(x: 1, y: 1), MockDataUnit(x: 0, y: 2), MockDataUnit(x: 0, y: 1)],
      [ExceptionDataUnit(isAccepted: true)],
      [MockDataUnit(x: 1, y: 0), MockDataUnit(x: 1, y: 2), MockDataUnit(x: 0, y: 0)],
      nil,
      [MockDataUnit(x: 2, y: 1), MockDataUnit(x: 0, y: 0)],
      [MockDataUnit(x: 2, y: 0), MockDataUnit(x: 0, y: 0)]
    ]
    let datasource = MockDatasource(columns: 3, rows: 3, dataSize: UInt(dataSet.count))
    
    let apiClient = MockAPIClient(datasource: datasource, dataSet: dataSet)
    let viewModel = DataGridViewModel(apiClient: apiClient)
    viewModel.loadDatasource()
    
    let snapshotExpectation = expectation(description: "Snapshot should be ready")
    var snapshot: DatasourceSnapshot?
    while snapshot == nil {
      snapshot = viewModel.snapshot(at: 0)
    }
    
    guard let actual = snapshot else {
      XCTFail("Unable to get snapshot")
      return
    }
    
    let expected = DatasourceSnapshot(appearanceResults: [
        DataUnitContainer(dataUnit: MockDataUnit(x: 0, y: 0)): 0.25
      ])
    XCTAssertTrue(actual.appearanceResults == expected.appearanceResults)
    snapshotExpectation.fulfill()
    
    wait(for: [snapshotExpectation], timeout: 10.0)
  }
  
  func testViewModelDelegate() {
    let datasource = MockDatasource(columns: 3, rows: 3, dataSize: 6)
    let dataSet: [[DataUnit]?] = [
      [MockDataUnit.random(in: datasource)],
      [MockDataUnit.random(in: datasource), MockDataUnit.random(in: datasource)],
      [ExceptionDataUnit(isAccepted: true)],
      [ExceptionDataUnit(isAccepted: false)],
      nil,
      [MockDataUnit.random(in: datasource), MockDataUnit.random(in: datasource)]]
    
    let apiClient = MockAPIClient(datasource: datasource, dataSet: dataSet)
    let viewModel = DataGridViewModel(apiClient: apiClient)
    let mockDelegate = MockViewModelDelegate(testCase: self)
    viewModel.delegate = mockDelegate
    viewModel.loadDatasource()
    mockDelegate.progressUpdatedExpectation.expectedFulfillmentCount = dataSet.count
    mockDelegate.failedExpectation.expectedFulfillmentCount = dataSet.compactMap { $0 as? [ExceptionDataUnit] }.count
    wait(for: [mockDelegate.startedExpectation, mockDelegate.failedExpectation,
               mockDelegate.completedExpectation, mockDelegate.progressUpdatedExpectation],
         timeout: 5.0)
  }
}

private extension DataGridViewModelTests {
  func isSame(lhs: Datasource, rhs: Datasource) -> Bool {
    return lhs.columns == rhs.columns
      && lhs.rows == rhs.rows
      && lhs.dataSize == rhs.dataSize
  }
  
  func isSame(lhs: [DataUnit]?, rhs: [DataUnit]?) -> Bool {
    guard let lhsUnits = lhs, let rhsUnits = rhs, lhsUnits.count == rhsUnits.count else {
      return lhs == nil && rhs == nil
    }
    return lhsUnits.elementsEqual(rhsUnits) { lhsUnit, rhsUnit -> Bool in
      return lhsUnit.x == rhsUnit.x && lhsUnit.y == rhsUnit.y
    }
  }
}

private class MockViewModelDelegate: DataGridViewModelDelegate {
  let startedExpectation: XCTestExpectation
  let completedExpectation: XCTestExpectation
  let progressUpdatedExpectation: XCTestExpectation
  let failedExpectation: XCTestExpectation
  init(testCase: XCTestCase) {
    startedExpectation = testCase.expectation(description: "loading.started")
    completedExpectation = testCase.expectation(description: "loading.completed")
    progressUpdatedExpectation = testCase.expectation(description: "loading.progress.updated")
    failedExpectation = testCase.expectation(description: "loading.failed")
  }
  
  func loadingStarted() {
    startedExpectation.fulfill()
  }
  
  func loadingCompleted(_ configuration: DatasourceConfiguration) {
    completedExpectation.fulfill()
  }
  
  func loadingProgressUpdated(_ progress: CGFloat) {
    progressUpdatedExpectation.fulfill()
  }
  
  func loadingFailedAt(_ index: Int) {
    failedExpectation.fulfill()
  }
}
