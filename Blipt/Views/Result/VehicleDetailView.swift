import SwiftUI

struct VehicleDetailView: View {
    @State private var viewModel: VehicleDetailViewModel
    @State private var showPaywall = false

    init(plate: String, isPremium: Bool) {
        _viewModel = State(initialValue: VehicleDetailViewModel(plate: plate, isPremium: isPremium))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.loadState {
                case .idle:
                    Color.clear
                case .loading:
                    LoadingOverlay()
                case .loaded(let vehicle):
                    vehicleContent(vehicle)
                case .error(let message):
                    errorContent(message)
                case .usageLimitReached:
                    usageLimitContent
                }
            }
            .background(Color.black)
            .navigationTitle("Vehicle Details")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchDetails()
            }
        }
    }

    private func vehicleContent(_ vehicle: VehicleInfo) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Plate header
                PlateVisualizerView(plate: PlateParseResult(
                    rawText: vehicle.registrationNumber,
                    normalizedPlate: formatPlate(vehicle.registrationNumber),
                    components: .indian(state: "", rtoCode: "", series: "", number: ""),
                    confidence: 1.0,
                    format: .standard
                ))

                // Verification badge
                VerificationBadgeView(level: VerificationLevel.compute(from: vehicle))

                // Vehicle info card
                vehicleInfoCard(vehicle)

                // Registration status
                registrationCard(vehicle)

                // Insurance
                InsuranceCardView(
                    company: vehicle.insuranceCompany,
                    validUntil: vehicle.insuranceUpto,
                    plate: vehicle.registrationNumber
                )

                // Fitness
                FitnessCardView(validUntil: vehicle.fitnessUpto)

                // Challans
                ChallanListView(challans: vehicle.challans ?? [])
            }
            .padding()
        }
    }

    private func vehicleInfoCard(_ vehicle: VehicleInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Vehicle", systemImage: "car.fill")
                .font(.headline)

            Divider()

            infoRow("Make", vehicle.make)
            infoRow("Model", vehicle.model)
            infoRow("Fuel", vehicle.fuelType)
            infoRow("Class", vehicle.vehicleClass)
            if let emission = vehicle.emissionNorms {
                infoRow("Emission", emission)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func registrationCard(_ vehicle: VehicleInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Registration", systemImage: "doc.text.fill")
                .font(.headline)

            Divider()

            HStack {
                Text("RC Status")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(vehicle.rcStatus)
                    .font(.subheadline.bold())
                    .foregroundStyle(vehicle.rcStatus == "ACTIVE" ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        (vehicle.rcStatus == "ACTIVE" ? Color.green : Color.red).opacity(0.15)
                    )
                    .clipShape(Capsule())
            }

            if let date = vehicle.registrationDate {
                infoRow("Registered", date.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.fetchDetails() }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    private var usageLimitContent: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "gauge.with.needle.fill")
                .font(.system(size: 56))
                .foregroundStyle(BliptTheme.premiumGold)
            Text("Free Lookups Used")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("You've used all 3 free vehicle lookups this month. Upgrade for unlimited access.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showPaywall = true
            } label: {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [BliptTheme.accent, BliptTheme.accentDeep],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .contentShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func formatPlate(_ raw: String) -> String {
        // Insert spaces for readability: MH12AB1234 → MH 12 AB 1234
        let cleaned = raw.replacingOccurrences(of: "[\\s\\-]", with: "", options: .regularExpression)
        guard cleaned.count >= 6 else { return raw }
        let state = cleaned.prefix(2)
        let rto = cleaned.dropFirst(2).prefix(2)
        let rest = cleaned.dropFirst(4)
        // Split rest into letters and numbers
        let letters = rest.prefix(while: { $0.isLetter })
        let numbers = rest.dropFirst(letters.count)
        return "\(state) \(rto) \(letters) \(numbers)"
    }
}
