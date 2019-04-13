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
  private(set) var processedItems: Int = 0 {
    didSet {
      delegate?.progressUpdated(processedItems)
    }
  }
  
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
    
    queue.async(execute: item)
    workItem = item
  }
  
  func stop() {
    workItem?.cancel()
    workItem = nil
    processedItems = 0
  }
  
  private func processDataTasks(_ dataTasks: [DataProcessTask]) -> [[DataUnit]?] {
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
  
  private func asyncLoad() -> DatasourceConfiguration {
    let datasource = apiClient.datasource
    
    let dataTasks: [DataProcessTask] = (0..<Int(datasource.dataSize)).map { index -> DataProcessTask in
      return DataProcessTask(index: index, apiClient: apiClient)
    }
    let taskQueue = DispatchQueue(label: "task.queue", attributes: .concurrent)
    let taskGroup = DispatchGroup()
    dataTasks.forEach {
      $0.load(in: taskQueue, group: taskGroup, maxRetry: 3) { [weak self] index in
        self?.processedItems += 1
      }
    }
    _ = taskGroup.wait(timeout: .distantFuture)
    let dataSet = processDataTasks(dataTasks)
    let flattend = Array(dataSet.compactMap { $0 }.joined())
    let appearanceMap = process(dataSet: flattend)
    let configuration = DatasourceConfiguration(dataSet: dataSet, appearanceMap: appearanceMap)
    return configuration
  }
}

private func process(dataSet: [DataUnit]) -> AppearanceMap {
  let dataUnitContainers = dataSet.map { DataUnitContainer(dataUnit: $0) }
  var appearanceMap: AppearanceMap = [:]
  dataUnitContainers.forEach { dataUnit in
    var current = appearanceMap[dataUnit] ?? 0
    current += 1
    appearanceMap[dataUnit] = current
  }
  return appearanceMap
}

typealias AppearanceMap = [DataUnitContainer: Int]

// FIXME: Workaround for not able to apply Hashable to DataUnit
struct DataUnitContainer: DataUnit, Hashable {
  let x: UInt
  let y: UInt
  init(dataUnit: DataUnit) {
    x = dataUnit.x
    y = dataUnit.y
  }
}

class DatasourceConfiguration {
  let dataSet: [[DataUnit]?]
  let appearanceMap: AppearanceMap
  
  init(dataSet: [[DataUnit]?], appearanceMap: AppearanceMap) {
    self.dataSet = dataSet
    self.appearanceMap = appearanceMap
  }
  
  func snapshot(at index: Int) -> DatasourceSnapshot {
    let slicedDataSet = Array(dataSet.prefix(upTo: index + 1).compactMap { $0 }.joined())
    let slicedApperanceMap = process(dataSet: slicedDataSet)
    return DatasourceSnapshot(appearanceResults: blend(slicedApperanceMap,
                                                       with: appearanceMap))
  }
  
  private func blend(_ lhs: AppearanceMap, with rhs: AppearanceMap) -> AppearanceResults {
    let list = lhs.compactMap { dataUnit, value -> (DataUnitContainer, Float)? in
      guard let rhsValue = rhs[dataUnit] else { return nil }
      let percentage = Float(value) / Float(rhsValue)
      return (dataUnit, percentage)
    }
    
    return AppearanceResults(uniqueKeysWithValues: list)
  }
}

typealias AppearanceResults = [DataUnitContainer: Float]
class DatasourceSnapshot {
  let appearanceResults: AppearanceResults
  init(appearanceResults: AppearanceResults) {
    self.appearanceResults = appearanceResults
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
  
  func load(in queue: DispatchQueue, group taskGroup: DispatchGroup, maxRetry: Int, completion: @escaping (Int) -> Void) {
    taskGroup.enter()
    queue.async { [weak self] in
      guard let sself = self else {
        taskGroup.leave()
        return
      }
      sself.getData(maxRetry: maxRetry)
      completion(sself.index)
      taskGroup.leave()
    }
  }
  
  private func getData(maxRetry: Int) {
    var failedAttempt = 0
    var finalResult: Result<[DataUnit]?, APIError> = .failed(.dataError)
    print("[\(index)] start")
    while failedAttempt < maxRetry {
      let result = apiClient.data(at: index)
      guard case .success(_) = result else {
        failedAttempt += 1
        print("[\(index)] Retry")
        continue
      }
      print("[\(index)] loaded")
      finalResult = result
      break
    }
    
    self.result = finalResult
  }
}

