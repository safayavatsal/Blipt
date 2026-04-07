import Foundation

struct VehicleLookupRequest: Codable {
    let plate: String
}

struct VahanAPIResponse: Codable {
    let success: Bool
    let data: VahanVehicleData?
    let error: String?
}

struct VahanVehicleData: Codable {
    let registrationNumber: String
    let makerDescription: String
    let makerModel: String
    let fuelType: String
    let vehicleClass: String
    let registrationDate: String?
    let fitnessUpto: String?
    let insuranceUpto: String?
    let insuranceCompany: String?
    let emissionNorms: String?
    let rcStatus: String
    let challanDetails: [VahanChallanDetail]?

    func toVehicleInfo() -> VehicleInfo {
        VehicleInfo(
            registrationNumber: registrationNumber,
            ownerName: nil, // PII stripped by backend
            make: makerDescription,
            model: makerModel,
            fuelType: fuelType,
            vehicleClass: vehicleClass,
            registrationDate: Self.parseDate(registrationDate),
            fitnessUpto: Self.parseDate(fitnessUpto),
            insuranceUpto: Self.parseDate(insuranceUpto),
            insuranceCompany: insuranceCompany,
            emissionNorms: emissionNorms,
            rcStatus: rcStatus,
            challans: challanDetails?.enumerated().map { index, c in
                ChallanRecord(
                    id: String(index),
                    date: Self.parseDate(c.date) ?? Date(),
                    amount: c.amount,
                    status: ChallanStatus(rawValue: c.status) ?? .pending,
                    violation: c.violation
                )
            }
        )
    }

    private static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Try multiple formats
        for format in ["yyyy-MM-dd", "dd-MM-yyyy", "dd/MM/yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}

struct VahanChallanDetail: Codable {
    let date: String
    let amount: Int
    let status: String
    let violation: String
}
