import SwiftUI

struct DataSubmissionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var submissionType = "missing_rto"
    @State private var regionCode = ""
    @State private var rtoCode = ""
    @State private var suggestedName = ""
    @State private var suggestedDistrict = ""
    @State private var notes = ""

    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var errorMessage: String?

    let country: Country

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you reporting?") {
                    Picker("Type", selection: $submissionType) {
                        Text("Missing RTO/City").tag("missing_rto")
                        Text("Incorrect Data").tag("incorrect_data")
                        Text("New RTO/City").tag("new_rto")
                    }
                }

                Section("Details") {
                    TextField(
                        country == .india ? "State Code (e.g. MH)" : "City Code (e.g. 42)",
                        text: $regionCode
                    )
                    .textInputAutocapitalization(.characters)

                    if country == .india {
                        TextField("RTO Code (e.g. MH99)", text: $rtoCode)
                            .textInputAutocapitalization(.characters)
                    }

                    TextField("Correct Name", text: $suggestedName)

                    if country == .india {
                        TextField("District", text: $suggestedDistrict)
                    }
                }

                Section("Additional Notes") {
                    TextField("Any extra info...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = errorMessage {
                    Section {
                        ErrorBannerView(message: error) {
                            errorMessage = nil
                        }
                    }
                }
            }
            .navigationTitle("Report Data Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || regionCode.isEmpty)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView("Submitting...")
                        .padding(24)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Submitted!", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you! Your report will be reviewed and the data will be updated.")
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil

        let submission = DataSubmission(
            country: country.rawValue,
            submissionType: submissionType,
            regionCode: regionCode.isEmpty ? nil : regionCode,
            rtoCode: rtoCode.isEmpty ? nil : rtoCode,
            suggestedName: suggestedName.isEmpty ? nil : suggestedName,
            suggestedDistrict: suggestedDistrict.isEmpty ? nil : suggestedDistrict,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            _ = try await SubmissionService().submitCorrection(submission)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}
