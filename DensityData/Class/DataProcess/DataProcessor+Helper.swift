//  Copyright © 2019 cincas. All rights reserved.

import Foundation

struct DataProcessorHelper {
  /// Convert given data set into appearance count map which indexed by `DataUnitContainer`
  static func process(dataSet: [DataUnit]) -> AppearanceMap {
    let dataUnitContainers = dataSet.map { DataUnitContainer(dataUnit: $0) }
    var appearanceMap: AppearanceMap = [:]
    dataUnitContainers.forEach { dataUnit in
      var current = appearanceMap[dataUnit] ?? 0
      current += 1
      appearanceMap[dataUnit] = current
    }
    return appearanceMap
  }
}
