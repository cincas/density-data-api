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
  
  func start(_ completion: @escaping (DatasourceConfiguration) -> Void) {
    workItem?.cancel()
    workItem = nil
    
    let item = DispatchWorkItem {
      completion(self.load())
    }
    queue.async(execute: item)
    workItem = item
  }
  
  func stop() {
    workItem?.cancel()
    workItem = nil
  }
  
  private func load() -> DatasourceConfiguration {
    let datasource = apiClient.datasource
    let dataSet = (0..<Int(datasource.dataSize)).map { index -> [DataUnit]? in
      let dataResult = getData(at: index, maxRetry: 3)
      delegate?.progressUpdated(index)
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
    
    let flattenDataSet = Array(dataSet.compactMap { $0 }.joined())
    let appearanceMap = process(dataSet: flattenDataSet)
    let configuration = DatasourceConfiguration(dataSet: dataSet,
                                                appearanceMap: appearanceMap)
    return configuration
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
