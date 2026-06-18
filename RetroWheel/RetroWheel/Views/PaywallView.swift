import SwiftUI

/// Paywall shown when a free-tier user tries to access a locked feature.
struct PaywallView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.10), Color(white: 0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .padding(16)
                }

                Spacer(minLength: 0)

                // Hero icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.22), Color(white: 0.14)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                    Image(systemName: "lock.open.rotation")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.bottom, 22)

                // Headline
                Text("Unlock RetroWheel")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)

                Text("One-time purchase · No subscription · No recurring charges")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 28)

                // Feature list
                featureList
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                Spacer(minLength: 0)

                // CTAs
                ctaStack
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "music.note.list",
                       text: "Full local library — unlimited songs")
            featureRow(icon: "text.badge.checkmark",
                       text: "All playlists")
            featureRow(icon: "antenna.radiowaves.left.and.right",
                       text: "Streaming library access")
            featureRow(icon: "paintpalette",
                       text: "All five shell colours")
            featureRow(icon: "infinity",
                       text: "Unlock once, yours forever")
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(width: 28)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.88))
        }
    }

    // MARK: - CTA buttons

    private var ctaStack: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchaseManager.purchase() }
            } label: {
                ZStack {
                    if purchaseManager.purchaseInProgress {
                        ProgressView().tint(.black)
                    } else {
                        Text("Unlock Forever — \(purchaseManager.formattedPrice)")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .cornerRadius(14)
            }
            .disabled(purchaseManager.purchaseInProgress)

            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                if purchaseManager.restoreInProgress {
                    ProgressView().tint(.white)
                } else {
                    Text("Restore Purchase")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
        }
    }
}

/// Small inline banner shown when the free-tier song cap is reached.
struct UpgradeBanner: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPaywall = false

    var body: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.yellow)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You've reached the free limit")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text("Unlock full access for \(purchaseManager.formattedPrice)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.6))
                }

                Spacer()

                Text("Unlock")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.07))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }
}
