import SwiftUI

// MARK: - Onboarding Page Model

private struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let showLogo: Bool
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        id: 0,
        icon: "camera.viewfinder",
        iconColor: BliptTheme.accent,
        title: "Point Your Camera",
        subtitle: "Scan any Indian license plate instantly",
        showLogo: true
    ),
    OnboardingPage(
        id: 1,
        icon: "mappin.circle.fill",
        iconColor: BliptTheme.radarGreen,
        title: "Instant Results",
        subtitle: "State, district, RTO office in seconds",
        showLogo: false
    ),
    OnboardingPage(
        id: 2,
        icon: "car.circle.fill",
        iconColor: BliptTheme.premiumGold,
        title: "Full Intelligence",
        subtitle: "Make, model, insurance, challans — everything",
        showLogo: false
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private var isLastPage: Bool { currentPage == onboardingPages.count - 1 }

    var body: some View {
        ZStack {
            BliptTheme.surfaceDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BliptTheme.textSecondary)
                    .padding(.trailing, 24)
                    .padding(.top, 8)
                }

                // Paged content
                TabView(selection: $currentPage) {
                    ForEach(onboardingPages) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Page indicators + button
                VStack(spacing: 28) {
                    // Custom page dots
                    HStack(spacing: 8) {
                        ForEach(onboardingPages) { page in
                            Capsule()
                                .fill(currentPage == page.id ? BliptTheme.accent : Color.white.opacity(0.25))
                                .frame(width: currentPage == page.id ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.25), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if isLastPage {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Text(isLastPage ? "Get Started" : "Next")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [BliptTheme.accent, BliptTheme.accentDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Single Onboarding Page

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if page.showLogo {
                BliptLogoView(size: 80, animated: true)
                    .padding(.bottom, 8)
            }

            Image(systemName: page.icon)
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(page.iconColor)
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, 8)

            Text(page.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(BliptTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.body)
                .foregroundStyle(BliptTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
