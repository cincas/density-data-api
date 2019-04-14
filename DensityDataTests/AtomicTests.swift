//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData
import DensityDataAPI

class AtomicTests: XCTestCase {
  func testReadWrite() {
    let atomic = Atomic<Int>(0)
    
    let queue = DispatchQueue(label: "atmoic.queue.tests")
    let taskGroup = DispatchGroup()
    let workItems: [DispatchWorkItem] = (0..<50).map { index in
      DispatchWorkItem {
        taskGroup.enter()
        atomic.modify { $0 += 1 }
        taskGroup.leave()
      }
    }
    
    workItems.forEach { queue.async(execute: $0) }
    
    let taskGroupExpectation = expectation(description: "Task group should be completed")
    taskGroup.notify(queue: queue) {
      XCTAssertEqual(atomic.value, workItems.count)
      taskGroupExpectation.fulfill()
    }
    
    wait(for: [taskGroupExpectation], timeout: 10.0)
  }
}
