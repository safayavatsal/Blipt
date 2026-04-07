import Foundation

struct MoroccanCity: Codable, Identifiable {
    let id: Int
    let name: String
    let coordinate: Coordinate?
}

struct MoroccanCitiesFile: Codable {
    let version: String
    let country: String
    let cities: [MoroccanCity]
}
