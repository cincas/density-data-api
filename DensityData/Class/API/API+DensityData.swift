//  Copyright © 2019 cincas. All rights reserved.

import DensityDataAPI

extension Grid: Datasource {}

extension DataPoint: DataUnit {}

extension DensityDataAPI: APIClient {
  var datasource: Datasource {
    return getGrid()
  }
  
  func data(at index: Int) -> Result<[DataUnit]?, APIError> {
    do {
      let dataUnits = try getData(index: UInt(index))
      return .success(dataUnits)
    } catch _ as DensityDataAPI.DataError {
      return .failed(.dataError)
    } catch {
      return .failed(.unknown(error))
    }
  }
}
