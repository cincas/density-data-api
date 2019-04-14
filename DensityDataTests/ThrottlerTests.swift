
//  Copyright © 2019 cincas. All rights reserved.

import XCTest
@testable import DensityData

class ThrottlerTests: XCTestCase {
  func testNonThrottlingTasks() {
    let pace: TimeInterval = 0.1
    let taskDuration = 0.2
    let throttler = Throttler(pace: pace, queue: DispatchQueue(label: "non-throttle.queue.test"))
    let throttleExpectation = expectation(description: "non-throttle")
    
    let tasks: [ThrottleTask] = (0..<10).map { index in
      return ThrottleTask(expectation: throttleExpectation, duration: taskDuration)
    }
    
    throttleExpectation.expectedFulfillmentCount = tasks.count
    var dispatchStart: TimeInterval = 0
    tasks.forEach { task in
      dispatch(task, in: throttler, after: dispatchStart)
      dispatchStart += taskDuration
    }
    wait(for: [throttleExpectation], timeout: 10)
  }
  
  func testThrottlingTasks() {
    let pace: TimeInterval = 0.1
    let taskDuration: TimeInterval = 0.01
    let throttler = Throttler(pace: pace, queue: DispatchQueue(label: "throttle.queue.test"))
    let throttleExpectation = expectation(description: "throttle")
    
    let tasks: [ThrottleTask] = (0..<10).map { index in
      return ThrottleTask(expectation: throttleExpectation, duration: taskDuration)
    }
    
    throttleExpectation.expectedFulfillmentCount = 2 // First and last
    tasks.forEach { task in
      throttler.start {
        task.execute()
      }
    }
    
    wait(for: [throttleExpectation], timeout: 10)
  }
  
  private let dispatchQueue = DispatchQueue(label: "throttle.test.dispatch.queues")
  func dispatch(_ task: ThrottleTask, in throttler: Throttler, after: TimeInterval) {
    let deadline: DispatchTime = .now() + .milliseconds(Int(after * 1000))
    dispatchQueue.asyncAfter(deadline: deadline) {
      throttler.start {
        task.execute()
      }
    }
  }
}

struct ThrottleTask {
  let expectation: XCTestExpectation
  let duration: TimeInterval
  init(expectation: XCTestExpectation, duration: TimeInterval) {
    self.expectation = expectation
    self.duration = duration
  }

  func execute() {
    let second : TimeInterval = 1000000
    usleep(useconds_t(Int(duration * second)))
    expectation.fulfill()

  }
}
