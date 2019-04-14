//  Copyright © 2019 cincas. All rights reserved.

import Foundation

typealias AppearanceMap = [DataUnitContainer: Int]
typealias AppearanceResults = [DataUnitContainer: Float]

class DatasourceConfiguration {
  private var snapshots: [Int: DatasourceSnapshot] = [:]
  init(dataSet: [[DataUnit]?], appearanceMap: AppearanceMap) {
    snapshots = buildSnapshots(from: dataSet, with: appearanceMap)
  }
  
  func snapshot(at index: Int) -> DatasourceSnapshot? {
    return snapshots[index]
  }
  
  private func buildSnapshots(from dataSet: [[DataUnit]?],
                              with appearanceMap: AppearanceMap) -> [Int: DatasourceSnapshot] {
    var snapshots: [Int: DatasourceSnapshot] = [:]
    (0..<dataSet.count).forEach { index in
      snapshots[index] = makeSnapshot(from: dataSet, with: appearanceMap, at: index)
    }
    return snapshots
  }
  
  private func makeSnapshot(from dataSet: [[DataUnit]?],
                            with appearanceMap: AppearanceMap,
                            at index: Int) -> DatasourceSnapshot {
    let slicedDataSet = Array(dataSet.prefix(upTo: index + 1).compactMap { $0 }.joined())
    let slicedApperanceMap = DataProcessorHelper.process(dataSet: slicedDataSet)
    let blended = blend(slicedApperanceMap,
                        with: appearanceMap)
    return DatasourceSnapshot(appearanceResults: blended)
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
