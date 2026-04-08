import SwiftUI

struct CompareView: View {
    let vehicleA: VehicleInfo
    let vehicleB: VehicleInfo

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Plate headers
                    HStack(spacing: 12) {
                        plateHeader(vehicleA.registrationNumber)
                        plateHeader(vehicleB.registrationNumber)
                    }

                    // Comparison rows
                    compareSection("Vehicle") {
                        compareRow("Make", a: vehicleA.make, b: vehicleB.make)
                        compareRow("Model", a: vehicleA.model, b: vehicleB.model)
                        compareRow("Fuel", a: vehicleA.fuelType, b: vehicleB.fuelType)
                        compareRow("Class", a: vehicleA.vehicleClass, b: vehicleB.vehicleClass)
                        if let eA = vehicleA.emissionNorms, let eB = vehicleB.emissionNorms {
                            compareRow("Emission", a: eA, b: eB)
                        }
                    }

                    compareSection("Registration") {
                        compareRow("RC Status", a: vehicleA.rcStatus, b: vehicleB.rcStatus, highlightDiff: true)
                        if let dA = vehicleA.registrationDate, let dB = vehicleB.registrationDate {
                            compareRow("Registered", a: dA.formatted(date: .abbreviated, time: .omitted), b: dB.formatted(date: .abbreviated, time: .omitted))
                        }
                    }

                    compareSection("Insurance") {
                        compareRow("Company", a: vehicleA.insuranceCompany ?? "N/A", b: vehicleB.insuranceCompany ?? "N/A")
                        compareRow("Valid Until",
                            a: vehicleA.insuranceUpto?.formatted(date: .abbreviated, time: .omitted) ?? "N/A",
                            b: vehicleB.insuranceUpto?.formatted(date: .abbreviated, time: .omitted) ?? "N/A",
                            highlightDiff: true
                        )
                    }

                    compareSection("Fitness") {
                        compareRow("Valid Until",
                            a: vehicleA.fitnessUpto?.formatted(date: .abbreviated, time: .omitted) ?? "N/A",
                            b: vehicleB.fitnessUpto?.formatted(date: .abbreviated, time: .omitted) ?? "N/A",
                            highlightDiff: true
                        )
                    }

                    compareSection("Challans") {
                        compareRow("Count",
                            a: "\(vehicleA.challans?.count ?? 0)",
                            b: "\(vehicleB.challans?.count ?? 0)",
                            highlightDiff: true
                        )
                        compareRow("Pending",
                            a: "\(vehicleA.challans?.filter { $0.status == .pending }.count ?? 0)",
                            b: "\(vehicleB.challans?.filter { $0.status == .pending }.count ?? 0)",
                            highlightDiff: true
                        )
                    }
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Compare Vehicles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func plateHeader(_ plate: String) -> some View {
        Text(plate)
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
    }

    private func compareSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 4)

            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func compareRow(_ label: String, a: String, b: String, highlightDiff: Bool = false) -> some View {
        let isDifferent = a != b

        return VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Text(a)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(highlightDiff && isDifferent ? .orange : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 16)
                    .overlay(Color.white.opacity(0.1))

                Text(b)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(highlightDiff && isDifferent ? .orange : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
