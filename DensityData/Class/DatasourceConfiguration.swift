//  Copyright © 2019 cincas. All rights reserved.

import Foundation

typealias AppearanceMap = [DataUnitContainer: Int]
typealias AppearanceResults = [DataUnitContainer: Float]

class DatasourceConfiguration {
  let dataSet: [[DataUnit]?]
  let appearanceMap: AppearanceMap
  
  init(dataSet: [[DataUnit]?], appearanceMap: AppearanceMap) {
    self.dataSet = dataSet
    self.appearanceMap = appearanceMap
  }
  
  func snapshot(at index: Int) -> DatasourceSnapshot {
    let slicedDataSet = Array(dataSet.prefix(upTo: index + 1).compactMap { $0 }.joined())
    let slicedApperanceMap = DataProcessorHelper.process(dataSet: slicedDataSet)
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

class DatasourceSnapshot {
  let appearanceResults: AppearanceResults
  init(appearanceResults: AppearanceResults) {
    self.appearanceResults = appearanceResults
  }
}

// FIXME: Workaround for not able to apply Hashable to DataUnit
struct DataUnitContainer: DataUnit, Hashable {
  let x: UInt
  let y: UInt
  init(dataUnit: DataUnit) {
    x = dataUnit.x
    y = dataUnit.y
  }
}
