import SwiftUI

/// "Was this result correct?" thumbs up/down after scan results.
struct FeedbackPromptView: View {
    let plateFormat: String
    let country: String
    let confidence: Double

    @State private var submitted = false
    @State private var selection: Bool?

    var body: some View {
        if submitted {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(BliptTheme.radarGreen)
                Text("Thanks for your feedback!")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.vertical, 8)
        } else {
            HStack(spacing: 16) {
                Text("Was this correct?")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Button {
                    submitFeedback(isCorrect: true)
                } label: {
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.title3)
                        .foregroundStyle(selection == true ? BliptTheme.radarGreen : .white.opacity(0.3))
                        .padding(8)
                        .background(selection == true ? BliptTheme.radarGreen.opacity(0.15) : Color.clear)
                        .clipShape(Circle())
                }

                Button {
                    submitFeedback(isCorrect: false)
                } label: {
                    Image(systemName: "hand.thumbsdown.fill")
                        .font(.title3)
                        .foregroundStyle(selection == false ? .red : .white.opacity(0.3))
                        .padding(8)
                        .background(selection == false ? Color.red.opacity(0.15) : Color.clear)
                        .clipShape(Circle())
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func submitFeedback(isCorrect: Bool) {
        selection = isCorrect

        // Send to backend (fire and forget, no PII)
        Task {
            let body: [String: Any] = [
                "plate_format": plateFormat,
                "country": country,
                "is_correct": isCorrect,
                "confidence": confidence,
            ]
            guard let url = URL(string: "\(AppConstants.apiBaseURL)/feedback"),
                  let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            try? await URLSession.shared.data(for: request)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            submitted = true
        }
    }
}
