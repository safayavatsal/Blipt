import Foundation

struct DataSubmission: Codable {
    let country: String
    let submissionType: String
    let regionCode: String?
    let rtoCode: String?
    let suggestedName: String?
    let suggestedDistrict: String?
    let notes: String?
}

struct SubmissionResponse: Codable {
    let success: Bool
    let submissionId: String
    let message: String
}

struct SubmissionService: Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func submitCorrection(_ submission: DataSubmission) async throws -> SubmissionResponse {
        try await apiClient.post(path: "submissions", body: submission)
    }
}
