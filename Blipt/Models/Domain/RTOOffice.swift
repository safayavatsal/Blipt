import Foundation

struct RTOOffice: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let fullCode: String
    let district: String
    let coordinate: Coordinate?
    let address: String?
    let phone: String?
    let workingHours: String?

    var id: String { fullCode }

    // CodingKeys with defaults for backward compatibility
    enum CodingKeys: String, CodingKey {
        case code, name, fullCode, district, coordinate, address, phone, workingHours
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        name = try container.decode(String.self, forKey: .name)
        fullCode = try container.decode(String.self, forKey: .fullCode)
        district = try container.decode(String.self, forKey: .district)
        coordinate = try container.decodeIfPresent(Coordinate.self, forKey: .coordinate)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        workingHours = try container.decodeIfPresent(String.self, forKey: .workingHours)
    }
}
