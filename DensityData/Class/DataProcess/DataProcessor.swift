//  Copyright © 2019 cincas. All rights reserved.

import Foundation

protocol DataProcessorDelegate: class {
  func progressStatusUpdate(_ status: DataProcessor.Status)
}

/// Load data from `APIClient` asynchronously and generate `DatasourceConfiguration`
class DataProcessor {
  /// Represent processing status
  enum Status {
    /// Amount of processed items
    case processed(Int)
    
    /// Building appearance snapshots
    case buildingSnapshots
    
    /// Loading data failed at index
    case failed(Int)
  }
  
  weak var delegate: DataProcessorDelegate?
  private let apiClient: APIClient
  private let queue = DispatchQueue(label: "data.process", qos: DispatchQoS.utility)
  private var workItem: DispatchWorkItem?
  private(set) var processedItems: Atomic<Int> = Atomic(0)
  
  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }
  
  /// Start async loading
  ///
  /// - Parameters:
  ///   - completion: Completion callback
  func start(_ completion: @escaping (DatasourceConfiguration) -> Void) {
    workItem?.cancel()
    workItem = nil
    
    let item = DispatchWorkItem { [unowned self] in
      completion(self.asyncLoad())
    }
    
    workItem = item
    queue.async(execute: item)
  }
  
  
  /// Stops loading process
  func stop() {
    workItem?.cancel()
    workItem = nil
    processedItems = Atomic(0)
  }
  
  deinit {
    stop()
  }
}

private extension DataProcessor {
  /// Actual async loading process
  ///
  /// - Returns: `DatasourceConfiguration` with pre-built snapshots
  func asyncLoad() -> DatasourceConfiguration {
    let datasource = apiClient.datasource
    
    let dataTasks: [DataProcessTask] = (0..<Int(datasource.dataSize)).map { index -> DataProcessTask in
      return DataProcessTask(index: index, apiClient: apiClient)
    }
    let taskQueue = DispatchQueue(label: "task.queue", attributes: .concurrent)
    let taskGroup = DispatchGroup()
    
    dataTasks.forEach {
      taskGroup.enter()
      $0.load(in: taskQueue, maxRetry: 3) { [weak self] index in
        self?.onDataProcessed()
        taskGroup.leave()
      }
    }
    
    _ = taskGroup.wait(timeout: .distantFuture)
    delegate?.progressStatusUpdate(.buildingSnapshots)
    let dataSet = processDataTasks(dataTasks)
    let flattend = Array(dataSet.compactMap { $0 }.joined())
    let appearanceMap = DataProcessorHelper.process(dataSet: flattend)
    let configuration = DatasourceConfiguration(dataSet: dataSet, appearanceMap: appearanceMap)
    return configuration
  }
  
  /// Collect results from completed data tasks
  ///
  /// - Parameters:
  ///   - dataTasks: An array of completed `DataProcessTask`
  ///
  /// - Returns: An array with `DataUnit` arrays
  func processDataTasks(_ dataTasks: [DataProcessTask]) -> [[DataUnit]?] {
    return dataTasks.sorted { $0.index < $1.index }
      .map { task -> [DataUnit]? in
        let index = task.index
        let dataResult = task.getResult()
        switch dataResult {
        case let .success(values):
          if let units = values {
            return units
          }
          
        case .failed(_):
          delegate?.progressStatusUpdate(.failed(index))
        }
        
        return nil
    }
  }
  
  /// Update `processedItems` and notify delegate
  func onDataProcessed() {
    processedItems.modify { [weak self] in
      $0 += 1
      self?.delegate?.progressStatusUpdate(.processed($0))
    }
  }
}

/// A wrapper class for handling `APIClient.data(at:)`
class DataProcessTask {
  private let apiClient: APIClient
  private var result: Result<[DataUnit]?, APIError>?
  let index: Int
  init(index: Int, apiClient: APIClient) {
    self.index = index
    self.apiClient = apiClient
  }
  
  /// Start request in given parameters
  ///
  /// - Parameters:
  ///   - queue: A `DispatchQueue` to execute request
  ///   - maxRetry: Maximum retry times
  ///   - completion: Completion callback
  func load(in queue: DispatchQueue,
            maxRetry: Int, completion: @escaping (Int) -> Void) {
    queue.async {
      self.getData(maxRetry: maxRetry, completion: completion)
    }
  }
  
  /// Get result
  ///
  /// Get final result for `APIClient.getData(at:)`
  /// If result was accessed before data is returned from request,
  /// default error `APIError.dataError` will return.
  func getResult() -> Result<[DataUnit]?, APIError> {
    return result ?? .failed(.dataError)
  }
  
  /// Get data from `APIClient` and handle result
  private func getData(maxRetry: Int, completion: @escaping (Int) -> Void) {
    var failedAttempt = 0
    var finalResult: Result<[DataUnit]?, APIError>? = nil
    while failedAttempt < maxRetry {
      let result = apiClient.data(at: index)
      guard case .success(_) = result else {
        failedAttempt += 1
        continue
      }
      finalResult = result
      break
    }
    self.result = finalResult
    completion(index)
  }
}
