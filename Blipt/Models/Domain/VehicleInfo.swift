import Foundation

struct VehicleInfo: Codable, Equatable {
    let registrationNumber: String
    let ownerName: String?
    let make: String
    let model: String
    let fuelType: String
    let vehicleClass: String
    let registrationDate: Date?
    let fitnessUpto: Date?
    let insuranceUpto: Date?
    let insuranceCompany: String?
    let emissionNorms: String?
    let rcStatus: String
    let challans: [ChallanRecord]?
}

struct ChallanRecord: Codable, Identifiable, Equatable {
    let id: String
    let date: Date
    let amount: Int
    let status: ChallanStatus
    let violation: String
}

enum ChallanStatus: String, Codable {
    case pending = "PENDING"
    case paid = "PAID"
}
