//  Copyright © 2019 cincas. All rights reserved.

import Foundation

/// Storing appearance total count
typealias AppearanceMap = [DataUnitContainer: Int]

// Storing percentage of current appearance in total
typealias AppearanceResults = [DataUnitContainer: Float]

/// Store snapshots for each data index
class DatasourceConfiguration {
  private var snapshots: [DatasourceSnapshot] = []
  private var maxAppearance: Int = 0
  init(dataSet: [[DataUnit]?], appearanceMap: AppearanceMap) {
    maxAppearance = DataProcessorHelper.processMaxAppearance(in: appearanceMap)
    snapshots = buildSnapshots(from: dataSet, with: appearanceMap)
  }

  func snapshot(at index: Int) -> DatasourceSnapshot? {
    return snapshots[index]
  }
  
  private func buildSnapshots(from dataSet: [[DataUnit]?],
                              with appearanceMap: AppearanceMap) -> [DatasourceSnapshot] {
    var lastAppearanceResult: AppearanceResults = [:]
    return dataSet.map { dataUnits -> AppearanceResults in
      guard let dataUnits = dataUnits else  {
        return lastAppearanceResult
      }
      
      let unitContainers = dataUnits.map { DataUnitContainer(dataUnit: $0) }
      unitContainers.forEach { unit in
        var current = lastAppearanceResult[unit] ?? 0
        current += Float(1) / Float(maxAppearance)
        lastAppearanceResult[unit] = current
      }
      
      return lastAppearanceResult
      }.map { DatasourceSnapshot(appearanceResults: $0) }
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
