//  Copyright © 2019 cincas. All rights reserved.

import Foundation

protocol APIClient {
  var datasource: Datasource { get }
  func data(at index: Int) -> Result<[DataUnit]?, APIError>
}

protocol Datasource {
  var columns: UInt { get }
  var rows: UInt { get }
  var dataSize: UInt { get }
}

protocol DataUnit {
  var x: UInt { get }
  var y: UInt { get }
}

enum APIError: LocalizedError {
  case dataError
  case unknown(Error)
}

enum Result<Value, Error: Swift.Error> {
  case success(Value)
  case failed(Error)
}

func ==(lhs: DataUnit, rhs: DataUnit) -> Bool {
  return lhs.x == rhs.x && lhs.y == rhs.y
}
