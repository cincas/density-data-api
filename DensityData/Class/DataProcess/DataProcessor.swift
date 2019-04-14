//  Copyright © 2019 cincas. All rights reserved.

import Foundation

protocol DataProcessorDelegate: class {
  func progressUpdated(_ progress: Int)
  func processFailed(at index: Int)
}

class DataProcessor {
  weak var delegate: DataProcessorDelegate?
  private let apiClient: APIClient
  private let queue = DispatchQueue(label: "data.process", qos: DispatchQoS.utility)
  private var workItem: DispatchWorkItem?
  private(set) var processedItems: Atmoic<Int> = Atmoic(0)
  
  init(apiClient: APIClient) {
    self.apiClient = apiClient
  }
  
  func start(_ completion: @escaping (DatasourceConfiguration) -> Void) {
    workItem?.cancel()
    workItem = nil
    
    let item = DispatchWorkItem { [weak self] in
      guard let sself = self else { return }
      completion(sself.asyncLoad())
    }
    
    workItem = item
    queue.async(execute: item)
  }
  
  func stop() {
    workItem?.cancel()
    workItem = nil
    processedItems = Atmoic(0)
  }
}

private extension DataProcessor {
  func processDataTasks(_ dataTasks: [DataProcessTask]) -> [[DataUnit]?] {
    return dataTasks.sorted { $0.index < $1.index }
      .map { task -> [DataUnit]? in
        let index = task.index
        guard let dataResult = task.result else {
          delegate?.processFailed(at: index)
          return nil
        }
        
        switch dataResult {
        case let .success(values):
          if let units = values {
            return units
          }
          
        case .failed(_):
          delegate?.processFailed(at: index)
        }
        
        return nil
    }
  }
  
  func onDataProcessed() {
    processedItems.modify { [weak self] in
      $0 += 1
      self?.delegate?.progressUpdated($0)
    }
  }
  
  func asyncLoad() -> DatasourceConfiguration {
    let datasource = apiClient.datasource
    
    let dataTasks: [DataProcessTask] = (0..<Int(datasource.dataSize)).map { index -> DataProcessTask in
      return DataProcessTask(index: index, apiClient: apiClient)
    }
    let taskQueue = DispatchQueue(label: "task.queue", attributes: .concurrent)
    let taskGroup = DispatchGroup()
    
    dataTasks.forEach {
      taskGroup.enter()
      $0.load(in: taskQueue, group: taskGroup, maxRetry: 3) { [weak self] index in
        self?.onDataProcessed()
        taskGroup.leave()
      }
    }
    
    _ = taskGroup.wait(timeout: .distantFuture)
    let dataSet = processDataTasks(dataTasks)
    let flattend = Array(dataSet.compactMap { $0 }.joined())
    let appearanceMap = DataProcessorHelper.process(dataSet: flattend)
    let configuration = DatasourceConfiguration(dataSet: dataSet, appearanceMap: appearanceMap)
    return configuration
  }
}

class DataProcessTask {
  let index: Int
  let apiClient: APIClient
  var result: Result<[DataUnit]?, APIError>?
  init(index: Int, apiClient: APIClient) {
    self.index = index
    self.apiClient = apiClient
  }
  
  func load(in queue: DispatchQueue, group taskGroup: DispatchGroup,
            maxRetry: Int, completion: @escaping (Int) -> Void) {
    queue.async {
      self.getData(maxRetry: maxRetry, completion: completion)
    }
  }
  
  private func getData(maxRetry: Int, completion: @escaping (Int) -> Void) {
    var failedAttempt = 0
    var finalResult: Result<[DataUnit]?, APIError> = .failed(.dataError)
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
