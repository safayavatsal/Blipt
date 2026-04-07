import SwiftUI

struct RTORowView: View {
    let rto: SubRegion

    var body: some View {
        HStack {
            Text(rto.code)
                .font(.subheadline.monospaced().bold())
                .foregroundStyle(BliptTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(BliptTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(rto.name)
                    .font(.subheadline.bold())
                Text(rto.district)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    List {
        RTORowView(rto: SubRegion(
            id: "MH12",
            code: "MH12",
            name: "Pune Central",
            district: "Pune",
            coordinate: Coordinate(lat: 18.52, lng: 73.86)
        ))
    }
}
