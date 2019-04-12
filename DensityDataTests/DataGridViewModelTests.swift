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
  
  func testGetData() {
    let datasource = MockDatasource.random()
    let dataSet: [[DataUnit]?] = [
      [MockDataUnit.random(in: datasource)],
      [MockDataUnit.random(in: datasource), MockDataUnit.random(in: datasource)],
      [ExceptionDataUnit(isAccepted: true)],
      [ExceptionDataUnit(isAccepted: false)],
      nil,
      [MockDataUnit.random(in: datasource), MockDataUnit.random(in: datasource)]]
    
    let apiClient = MockAPIClient(datasource: MockDatasource.random(), dataSet: dataSet)
    let viewModel = DataGridViewModel(apiClient: apiClient)
    dataSet.enumerated().forEach { index, expected in
      let actual = viewModel.getData(at: index)
      switch actual {
      case let .success(values):
        XCTAssertTrue(isSame(lhs: values, rhs: expected))
        
      case let .failed(error):
        switch error {
        case .dataError:
          let acceptedException = expected?.compactMap { $0 as? ExceptionDataUnit }
            .first { $0.isAccepted }
          XCTAssertTrue(acceptedException != nil)
          
        case .unknown(_):
          let unacceptedException = expected?.compactMap { $0 as? ExceptionDataUnit }
            .first { !$0.isAccepted }
          XCTAssertTrue(unacceptedException != nil)
        }
        break
      }
    }
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
  
  func loadingCompleted() {
    completedExpectation.fulfill()
  }
  
  func loadingProgressUpdated(_ progress: CGFloat) {
    progressUpdatedExpectation.fulfill()
  }
  
  func loadingFailedAt(_ index: Int) {
    failedExpectation.fulfill()
  }
}
