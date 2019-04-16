//  Copyright © 2019 cincas. All rights reserved.

import Foundation

/// Storing appearance total count
typealias AppearanceMap = [DataUnitContainer: Int]

// Storing percentage of current appearance in total
typealias AppearanceResults = [DataUnitContainer: Float]

/// Store snapshots for each data index
class DatasourceConfiguration {
  private var snapshots: [Int: DatasourceSnapshot] = [:]
  private var maxAppearance: Int = 0
  init(dataSet: [[DataUnit]?], appearanceMap: AppearanceMap) {
    maxAppearance = DataProcessorHelper.processMaxAppearance(in: appearanceMap)
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
    let blended = blend(slicedApperanceMap)
    return DatasourceSnapshot(appearanceResults: blended)
  }

  private func blend(_ appearanceMap: AppearanceMap) -> AppearanceResults {
    let list = appearanceMap.compactMap { dataUnit, value -> (DataUnitContainer, Float)? in
      let percentage = Float(value) / Float(maxAppearance)
      return (dataUnit, percentage)
    }
    
    return AppearanceResults(uniqueKeysWithValues: list)
  }
}

/// Represents a list of `DataUnit`'s appearance in percentage at certain point
class DatasourceSnapshot {
  let appearanceResults: AppearanceResults
  init(appearanceResults: AppearanceResults) {
    self.appearanceResults = appearanceResults
  }
}

// Workaround for not being able to apply Hashable to DataUnit
struct DataUnitContainer: DataUnit, Hashable {
  let x: UInt
  let y: UInt
  init(dataUnit: DataUnit) {
    x = dataUnit.x
    y = dataUnit.y
  }
}
