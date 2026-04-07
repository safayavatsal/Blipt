import Foundation

struct IndianState: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let type: StateType
    let capital: String
    let coordinate: Coordinate
    let rtos: [RTOOffice]

    var id: String { code }
}

enum StateType: String, Codable {
    case state
    case ut
}

struct Coordinate: Codable, Hashable {
    let lat: Double
    let lng: Double
}
