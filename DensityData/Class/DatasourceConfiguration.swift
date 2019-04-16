//  Copyright © 2019 cincas. All rights reserved.

import Foundation

/// Storing appearance total count
typealias AppearanceMap = [DataUnitContainer: Int]

/// Represents a list of `DataUnit`'s appearance in percentage at certain point
typealias DatasourceSnapshot = [DataUnitContainer: Float]

/// Store snapshots for each data index
class DatasourceConfiguration {
  private var snapshots: [DatasourceSnapshot] = []
  private var maxAppearance: Int = 0
  init(dataSet: [[DataUnit]?], appearanceMap: AppearanceMap) {
    if let maxAppearance = (appearanceMap.max { $0.value < $1.value }?.value) {
      self.maxAppearance = maxAppearance
    }
    snapshots = buildSnapshots(from: dataSet, with: appearanceMap)
  }

  func snapshot(at index: Int) -> DatasourceSnapshot? {
    return snapshots[index]
  }
  
  private func buildSnapshots(from dataSet: [[DataUnit]?],
                              with appearanceMap: AppearanceMap) -> [DatasourceSnapshot] {
    var lastAppearanceResult: DatasourceSnapshot = [:]
    return dataSet.map { dataUnits -> DatasourceSnapshot in
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
      }
  }
}

// Workaround for not being able to apply Hashable to DataUnit
struct DataUnitContainer: DataUnit, Hashable {
  let x: UInt
  let y: UInt
  init(x: UInt, y: UInt) {
    self.x = x
    self.y = y
  }
  
  init(dataUnit: DataUnit) {
    self.init(x: dataUnit.x, y: dataUnit.y)
  }
}
