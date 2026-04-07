import SwiftUI

struct ChallanListView: View {
    let challans: [ChallanRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Challans", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                Spacer()
                if !challans.isEmpty {
                    Text("\(challans.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(pendingCount > 0 ? .red : .green)
                        .clipShape(Capsule())
                }
            }

            Divider()

            if challans.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("No challans found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(challans) { challan in
                    challanRow(challan)
                    if challan.id != challans.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var pendingCount: Int {
        challans.filter { $0.status == .pending }.count
    }

    private func challanRow(_ challan: ChallanRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(challan.violation)
                    .font(.subheadline.weight(.medium))
                Text(challan.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(challan.amount)")
                    .font(.subheadline.bold())
                Text(challan.status.rawValue)
                    .font(.caption2.bold())
                    .foregroundStyle(challan.status == .paid ? .green : .orange)
            }
        }
    }
}

#Preview("With Challans") {
    ChallanListView(challans: [
        ChallanRecord(id: "1", date: Date().addingTimeInterval(-86400 * 30), amount: 500, status: .pending, violation: "Signal jumping"),
        ChallanRecord(id: "2", date: Date().addingTimeInterval(-86400 * 90), amount: 1000, status: .paid, violation: "Overspeeding"),
    ])
    .padding()
}

#Preview("No Challans") {
    ChallanListView(challans: [])
        .padding()
}
