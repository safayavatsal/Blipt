import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    private let totalPages = 3
    private var isLastPage: Bool { currentPage == totalPages - 1 }

    var body: some View {
        ZStack {
            BliptTheme.surfaceDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("Skip") {
                            hasCompletedOnboarding = true
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.trailing, 24)
                        .padding(.top, 12)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }

                // Pages
                TabView(selection: $currentPage) {
                    page1.tag(0)
                    page2.tag(1)
                    page3.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Bottom: indicators + button
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            Capsule()
                                .fill(currentPage == i ? BliptTheme.accent : Color.white.opacity(0.2))
                                .frame(width: currentPage == i ? 28 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.25), value: currentPage)
                        }
                    }

                    // Action button
                    Button {
                        if isLastPage {
                            hasCompletedOnboarding = true
                        } else {
                            withAnimation { currentPage += 1 }
                        }
                    } label: {
                        Text(isLastPage ? "Get Started" : "Continue")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [BliptTheme.accent, BliptTheme.accentDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: BliptTheme.accent.opacity(0.3), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Page 1: Scan

    private var page1: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration area
            ZStack {
                // Outer glow
                Circle()
                    .fill(BliptTheme.accent.opacity(0.08))
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(BliptTheme.accent.opacity(0.04))
                    .frame(width: 280, height: 280)

                // Camera icon with plate
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 72, weight: .ultraLight))
                        .foregroundStyle(BliptTheme.accent)

                    // Mini plate
                    Text("MH 12 AB 1234")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            Spacer()
                .frame(height: 48)

            // Text
            VStack(spacing: 12) {
                Text("Point Your Camera")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Aim at any Indian license plate.\nBlipt reads it instantly using on-device AI —\nno internet needed.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 2: Results

    private var page2: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration: result card mock
            VStack(spacing: 12) {
                // Mini plate
                HStack(spacing: 0) {
                    Text("IND")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22)
                        .frame(maxHeight: .infinity)
                        .background(BliptTheme.accentDeep)

                    Text("MH 12 AB 1234")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Result items
                VStack(spacing: 10) {
                    resultRow(icon: "mappin.circle.fill", label: "State", value: "Maharashtra", color: BliptTheme.radarGreen)
                    resultRow(icon: "building.2.fill", label: "District", value: "Pune", color: BliptTheme.accent)
                    resultRow(icon: "doc.text.fill", label: "RTO", value: "Pune Central", color: .orange)
                }
                .padding(16)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Map placeholder
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 60)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "map.fill")
                                .foregroundStyle(BliptTheme.accent.opacity(0.5))
                            Text("Map Location")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    )
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 48)

            // Text
            VStack(spacing: 12) {
                Text("Instant Results")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Get the state, district, and RTO office\nfor any plate — with a map pin showing\nexactly where it's registered.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 3: Premium

    private var page3: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration: premium features
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(BliptTheme.premiumGold)
                    Text("Premium Intelligence")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BliptTheme.premiumGold)
                    Spacer()
                }
                .padding(.bottom, 16)

                VStack(spacing: 14) {
                    premiumRow(icon: "car.fill", text: "Vehicle make, model & class", color: BliptTheme.accent)
                    premiumRow(icon: "shield.checkered", text: "Insurance status & company", color: BliptTheme.radarGreen)
                    premiumRow(icon: "exclamationmark.triangle.fill", text: "Challan history & fines", color: .orange)
                    premiumRow(icon: "checkmark.seal.fill", text: "Fitness certificate validity", color: BliptTheme.premiumGold)
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(BliptTheme.premiumGold.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 48)

            // Text
            VStack(spacing: 12) {
                Text("Full Vehicle Intelligence")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Unlock everything about any vehicle.\nMake, insurance, challans, fitness —\nall from a single scan.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Helpers

    private func resultRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
    }

    private func premiumRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(BliptTheme.radarGreen)
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
