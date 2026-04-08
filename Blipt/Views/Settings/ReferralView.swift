import SwiftUI

struct ReferralView: View {
    @State private var referralManager = ReferralManager()
    @State private var usageTracker = UsageTracker()
    @State private var redeemCode = ""
    @State private var redeemMessage: String?
    @State private var redeemSuccess = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(BliptTheme.premiumGold)
                            Text("Refer a Friend")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Give 3 free lookups, get 3 free lookups")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 12)

                        // Your code
                        VStack(spacing: 12) {
                            Text("Your Referral Code")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white.opacity(0.5))

                            Text(referralManager.referralCode)
                                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                                .foregroundStyle(BliptTheme.accent)
                                .tracking(4)

                            ShareLink(item: referralManager.shareMessage) {
                                Label("Share Code", systemImage: "square.and.arrow.up")
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
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Stats
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("\(referralManager.referralCount)")
                                    .font(.title.bold())
                                    .foregroundStyle(BliptTheme.radarGreen)
                                Text("Friends Referred")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 4) {
                                Text("\(referralManager.referralCount * 3)")
                                    .font(.title.bold())
                                    .foregroundStyle(BliptTheme.premiumGold)
                                Text("Bonus Lookups Earned")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Redeem code
                        VStack(spacing: 12) {
                            Text("Have a code from a friend?")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))

                            HStack(spacing: 12) {
                                TextField("Enter code", text: $redeemCode)
                                    .font(.system(.body, design: .monospaced))
                                    .textInputAutocapitalization(.characters)
                                    .autocorrectionDisabled()
                                    .padding(12)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .foregroundStyle(.white)

                                Button("Redeem") {
                                    redeem()
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(BliptTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .disabled(redeemCode.count < 8 || referralManager.hasRedeemedCode)
                            }

                            if let msg = redeemMessage {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(redeemSuccess ? .green : .red)
                            }

                            if referralManager.hasRedeemedCode {
                                Text("You've already redeemed a code")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.3))
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Referrals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func redeem() {
        if referralManager.redeemCode(redeemCode, usageTracker: usageTracker) {
            redeemMessage = "3 bonus lookups added!"
            redeemSuccess = true
        } else {
            redeemMessage = "Invalid code or already redeemed."
            redeemSuccess = false
        }
    }
}
