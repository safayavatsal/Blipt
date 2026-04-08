import SwiftUI
import MapKit

struct RTODetailView: View {
    let rto: RTOOffice
    let stateName: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(rto.fullCode)
                        .font(.system(size: 32, weight: .heavy, design: .monospaced))
                        .foregroundStyle(BliptTheme.accent)
                    Text(rto.name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("\(rto.district), \(stateName)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.top, 8)

                // Map
                if let coord = rto.coordinate {
                    MapSnippetView(
                        coordinate: CLLocationCoordinate2D(latitude: coord.lat, longitude: coord.lng),
                        title: rto.name
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Details card
                VStack(alignment: .leading, spacing: 16) {
                    if let address = rto.address {
                        detailRow(icon: "mappin.circle.fill", label: "Address", value: address)
                    }

                    if let phone = rto.phone {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundStyle(BliptTheme.radarGreen)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.4))
                                Text(phone)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                            Button {
                                callPhone(phone)
                            } label: {
                                Image(systemName: "phone.arrow.up.right")
                                    .font(.subheadline)
                                    .padding(8)
                                    .background(BliptTheme.radarGreen.opacity(0.15))
                                    .clipShape(Circle())
                                    .foregroundStyle(BliptTheme.radarGreen)
                            }
                        }
                    }

                    if let hours = rto.workingHours {
                        detailRow(icon: "clock.fill", label: "Working Hours", value: hours)
                    }

                    // District info
                    detailRow(icon: "building.2.fill", label: "District", value: rto.district)
                }
                .padding(20)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Get Directions button
                if let coord = rto.coordinate {
                    Button {
                        openInMaps(coordinate: coord, name: rto.name)
                    } label: {
                        Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(BliptTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .contentShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("RTO Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(BliptTheme.accent)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private func openInMaps(coordinate: Coordinate, name: String) {
        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lng))
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = name
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func callPhone(_ number: String) {
        let cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        if let url = URL(string: "tel:\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
}
