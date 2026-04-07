import Foundation

protocol PlateParserProtocol {
    var country: Country { get }
    func parse(ocrText: String) -> PlateParseResult?
    func validate(plate: String) -> Bool
}

enum PlateParserFactory {
    static func parser(for country: Country) -> PlateParserProtocol {
        switch country {
        case .india:
            IndianPlateParser()
        case .morocco:
            MoroccanPlateParser()
        }
    }
}
