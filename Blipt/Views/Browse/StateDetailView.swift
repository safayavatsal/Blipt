import SwiftUI
import MapKit

struct StateDetailView: View {
    let region: Region
    @State private var searchQuery = ""

    var filteredRTOs: [SubRegion] {
        if searchQuery.isEmpty {
            return region.subRegions
        }
        return region.subRegions.filter {
            $0.code.localizedCaseInsensitiveContains(searchQuery) ||
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.district.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var body: some View {
        List {
            // Map section showing all RTO pins
            Section {
                let annotations = region.subRegions.compactMap { rto -> RTOAnnotation? in
                    guard let coord = rto.coordinate else { return nil }
                    return RTOAnnotation(
                        name: rto.code,
                        coordinate: CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng)
                    )
                }
                if !annotations.isEmpty {
                    Map {
                        ForEach(annotations) { pin in
                            Marker(pin.name, coordinate: pin.coordinate)
                                .tint(.red)
                        }
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
            }

            // RTO list
            Section("\(filteredRTOs.count) RTOs") {
                ForEach(filteredRTOs) { rto in
                    RTORowView(rto: rto)
                }
            }
        }
        .navigationTitle(region.name)
        .searchable(text: $searchQuery, prompt: "Search RTOs in \(region.name)")
    }
}

private struct RTOAnnotation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}
