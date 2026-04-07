import SwiftUI

struct ManualEntryView: View {
    @State private var plateText = ""
    @State private var isProcessing = false
    @State private var result: (PlateParseResult, LocationInfo?)?
    @State private var errorMessage: String?
    @State private var showResult = false

    @Environment(\.dismiss) private var dismiss

    let parser: PlateParserProtocol
    let dataService: CountryDataServiceProtocol
    let historyStore: ScanHistoryStore
    let country: Country

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Plate preview
                    if !plateText.isEmpty {
                        Text(plateText.uppercased())
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.gray.opacity(0.5), lineWidth: 2)
                            )
                            .shadow(color: BliptTheme.accent.opacity(0.15), radius: 8, y: 4)
                    } else {
                        Text("MH 12 AB 1234")
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundStyle(.gray.opacity(0.3))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                    }

                    // Text field
                    TextField("Enter plate number", text: $plateText)
                        .font(.title3.weight(.medium))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    // Look Up button
                    Button {
                        lookUp()
                    } label: {
                        Text("Look Up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
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
                    .disabled(plateText.trimmingCharacters(in: .whitespaces).count < 4)
                    .opacity(plateText.trimmingCharacters(in: .whitespaces).count < 4 ? 0.5 : 1.0)

                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showResult) {
                if let (plate, location) = result {
                    PlateResultView(plate: plate, location: location, image: nil)
                        .environment(AppState())
                }
            }
        }
    }

    private func lookUp() {
        errorMessage = nil
        guard let parseResult = parser.parse(ocrText: plateText) else {
            errorMessage = "Invalid plate format. Try something like MH12AB1234."
            return
        }

        let location = dataService.lookup(plate: parseResult)
        result = (parseResult, location)

        // Save to history
        let item = ScanHistoryItem(
            plate: parseResult.rawText,
            normalizedPlate: parseResult.normalizedPlate,
            stateName: location?.stateName,
            stateCode: location?.stateCode,
            districtName: location?.districtName,
            rtoName: location?.rtoName,
            country: country.rawValue,
            format: parseResult.format.rawValue,
            confidence: parseResult.confidence
        )
        historyStore.add(item)

        showResult = true
    }
}
