import SwiftUI

@Observable @MainActor
final class BrowseViewModel {
    var searchQuery: String = ""
    var regions: [Region] = []
    var isLoading = true

    private var dataService: CountryDataServiceProtocol
    private let indianDataService = RTODataService()
    private let moroccoDataService = MoroccoDataService()

    private(set) var country: Country

    init(country: Country = .india) {
        self.country = country
        self.dataService = RTODataService() // placeholder
        switch country {
        case .india: self.dataService = indianDataService
        case .morocco: self.dataService = moroccoDataService
        }
    }

    func switchCountry(_ newCountry: Country) {
        guard newCountry != country else { return }
        country = newCountry
        switch newCountry {
        case .india: dataService = indianDataService
        case .morocco: dataService = moroccoDataService
        }
        regions = []
        Task { await loadData() }
    }

    func loadData() async {
        isLoading = true
        try? await dataService.loadData()
        regions = dataService.allRegions()
        isLoading = false
    }

    var filteredRegions: [Region] {
        if searchQuery.isEmpty {
            return regions
        }
        return dataService.search(query: searchQuery)
    }

    var totalCount: Int {
        regions.reduce(0) { $0 + $1.subRegions.count }
    }
}
