//  Copyright © 2019 cincas. All rights reserved.

import Foundation

final class Atomic<T> {
  private let queue = DispatchQueue(label: "atomic.queue")
  private var _value: T
  init(_ value: T) {
    self._value = value
  }
  
  var value: T {
    get { return queue.sync { _value} }
  }
  
  func modify(_ transform: (inout T) -> ()) {
    queue.sync { transform(&_value) }
  }
}
