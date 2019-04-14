//  Copyright © 2019 cincas. All rights reserved.

import Foundation

/// Throttling execution in given pace
class Throttler {
  private var currentTask: DispatchWorkItem?
  /// Last task which violated regulated frequency
  private var pendingTask: DispatchWorkItem?
  private var lastTaskTime = Date.distantPast
  
  /// Queue to dispatch tasks
  let queue: DispatchQueue
  
  /// Regulated frequency for tasks
  let pace: TimeInterval
  
  init(pace: TimeInterval, queue: DispatchQueue = DispatchQueue(label: "throttler.queue")) {
    self.pace = pace
    self.queue = queue
  }
  
  /// Start given task
  ///
  /// Only one task can be executed in given value.
  /// If a task's request time is less than regulated frequency (pace),
  /// it will be cached into `pendingTask` and will be runned at the end.
  func start(_ closure: @escaping () -> Void) {
    let sinceLastRun = Date().timeIntervalSince(lastTaskTime)
    guard sinceLastRun >= pace else {
      // Schedule racing task
      later(after: pace - sinceLastRun, closure)
      return
    }
    
    currentTask?.cancel()
    currentTask = nil
    let item = DispatchWorkItem {
      closure()
    }
    currentTask = item
    queue.async(execute: item)
    lastTaskTime = Date()
  }
  
  
  /// Schedule racing task
  private func later(after: TimeInterval, _ closure: @escaping () -> Void) {
    pendingTask?.cancel()
    pendingTask = nil
    let item = DispatchWorkItem(block: closure)
    let deadline: DispatchTime = .now() + .milliseconds(Int(after * 1000))
    queue.asyncAfter(deadline: deadline, execute: item)
    pendingTask = item
  }
}
