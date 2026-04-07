import Foundation

struct PlateParseResult: Equatable {
    let rawText: String
    let normalizedPlate: String
    let components: PlateComponents
    let confidence: Double
    let format: PlateFormat
}

enum PlateComponents: Equatable {
    case indian(state: String, rtoCode: String, series: String, number: String)
    case indianBH(year: String, number: String, category: String)
    case moroccan(cityCode: Int)
}

enum PlateFormat: String {
    case standard
    case bhSeries
    case moroccan
}

struct LocationInfo: Equatable {
    let stateName: String
    let stateCode: String
    let districtName: String
    let rtoName: String
    let coordinate: Coordinate?
}
