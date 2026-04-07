import Foundation

struct RTOOffice: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let fullCode: String
    let district: String
    let coordinate: Coordinate?

    var id: String { fullCode }
}
