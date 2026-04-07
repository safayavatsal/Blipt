import SwiftUI
import MapKit

struct MapSnippetView: View {
    let coordinate: CLLocationCoordinate2D
    let title: String

    var body: some View {
        Map {
            Marker(title, coordinate: coordinate)
                .tint(.red)
        }
        .mapStyle(.standard(elevation: .realistic))
        .allowsHitTesting(false)
    }
}

#Preview {
    MapSnippetView(
        coordinate: CLLocationCoordinate2D(latitude: 18.5204, longitude: 73.8567),
        title: "Pune RTO"
    )
    .frame(height: 200)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .padding()
}
