//  Copyright © 2019 cincas. All rights reserved.

import Foundation

class Throttler {
  private var currentTask: DispatchWorkItem?
  private var pendingTask: DispatchWorkItem?
  private var lastTaskTime = Date.distantPast
  let queue: DispatchQueue
  let pace: TimeInterval
  
  init(pace: TimeInterval, queue: DispatchQueue = DispatchQueue(label: "throttler.queue")) {
    self.pace = pace
    self.queue = queue
  }
  
  func start(_ closure: @escaping () -> Void) {
    let sinceLastRun = Date().timeIntervalSince(lastTaskTime)
    guard sinceLastRun >= pace else {
      // Scedule racing tasks
      
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
  
  private func later(after: TimeInterval, _ closure: @escaping () -> Void) {
    pendingTask?.cancel()
    pendingTask = nil
    let item = DispatchWorkItem(block: closure)
    let deadline: DispatchTime = .now() + .milliseconds(Int(after * 1000))
    queue.asyncAfter(deadline: deadline, execute: item)
    pendingTask = item
  }
}
