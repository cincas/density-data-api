//  Copyright © 2019 cincas. All rights reserved.

import Foundation

protocol DataProcessorDelegate: class {
  func progressUpdated(_ progress: Int)
  func processFailed(at index: Int)
}

class DataProcessor {
  private let apiClient: APIClient
  private let queue = DispatchQueue(label: "data.process", qos: DispatchQoS.utility)
  private var workItem: DispatchWorkItem?
  weak var delegate: DataProcessorDelegate?
  
  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }
  
  func start(_ completion: @escaping ([DataUnit]) -> Void) {
    workItem?.cancel()
    workItem = nil
    
    let item = DispatchWorkItem {
      completion(self.load())
    }
    
    queue.asyncAfter(deadline: .now() + .seconds(3), execute: item)
    workItem = item
  }
  
  func stop() {
    workItem?.cancel()
    workItem = nil
  }
  
  private func load() -> [DataUnit] {
    let datasource = apiClient.datasource
    let flattenDataSet: [DataUnit] = (0..<Int(datasource.dataSize)).reduce([]) { (last, index) -> [DataUnit] in
      let dataResult = getData(at: index, maxRetry: 3)
      var result = last
      switch dataResult {
      case let .success(values):
        if let units = values {
          result.append(contentsOf: units)
        }
        
      case .failed(_):
        delegate?.processFailed(at: index)
      }
      delegate?.progressUpdated(index)
      return result
    }
    return flattenDataSet
  }
  
  private func getData(at index: Int, maxRetry: Int) -> Result<[DataUnit]?, APIError> {
    var failedAttempt = 0
    while failedAttempt < maxRetry {
      let result = apiClient.data(at: index)
      guard case .success(_) = result else {
        failedAttempt += 1
        print("[\(index)] Retry")
        continue
      }
      
      return result
    }
    
    return .failed(.dataError)
  }
}
