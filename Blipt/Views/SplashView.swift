import SwiftUI

struct SplashView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isSplashDone = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        if isSplashDone {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        BliptTheme.surfaceDark,
                        Color(red: 0.03, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    BliptLogoView(size: 140, animated: true)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Text("Blipt")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BliptTheme.accent, BliptTheme.radarGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)

                    Text("Vehicle Intelligence, Instantly.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .opacity(textOpacity)

                    Spacer()
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                    textOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isSplashDone = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environment(AppState())
}
