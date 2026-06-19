import SwiftUI
import MusicKit

struct SettingsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var appSettings: AppSettings
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List {
                // Unlock banner (shown only while not yet purchased)
                if !purchaseManager.hasFullAccess {
                    Section { unlockBannerRow }
                        .listSectionSpacing(8)
                }

                // Shell colour picker
                Section("Shell Colour") { shellColorPicker }
                    .listSectionSpacing(8)

                // Interaction
                Section("Interaction") {
                    toggleRow(
                        icon: "hand.tap",
                        label: "Haptic Feedback",
                        color: .blue,
                        isOn: $appSettings.hapticsEnabled
                    )
                    toggleRow(
                        icon: "speaker.wave.1",
                        label: "Click Sounds",
                        color: .green,
                        isOn: $appSettings.clickSoundsEnabled
                    )
                    sensitivityRow
                }
                .listSectionSpacing(8)

                // Music sources
                Section("Music Sources") {
                    streamingRow
                    localLibraryRow
                }
                .listSectionSpacing(8)

                // About
                Section("About") {
                    labelRow(icon: "app.badge", label: "Version", value: "1.0")
                    labelRow(icon: "purchased",
                             label: "License",
                             value: purchaseManager.isUnlocked ? "Unlocked" : "Free")
                    Button("Restore Purchase") {
                        Task { await purchaseManager.restorePurchases() }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .listRowBackground(Color.white.opacity(0.07))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }

    // MARK: - Unlock banner

    private var unlockBannerRow: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.yellow)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock full access")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.white)
                    Text("One-time \(purchaseManager.formattedPrice) · No subscription")
                        .font(.system(size: 12))
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
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.yellow.opacity(0.08))
    }

    // MARK: - Shell colour picker

    private var shellColorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(ShellColor.allCases) { color in
                    colorSwatch(color)
                }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
    }

    private func colorSwatch(_ color: ShellColor) -> some View {
        let isSelected  = appSettings.shellColor == color
        let isAvailable = purchaseManager.hasFullAccess || color == .black
        return Button {
            if isAvailable {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    appSettings.shellColor = color
                }
                if appSettings.hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } else {
                showPaywall = true
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: color.bodyGradient,
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                        .opacity(isAvailable ? 1.0 : 0.45)
                    if isSelected && isAvailable {
                        Circle()
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: 46, height: 46)
                    }
                    if !isAvailable {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                Text(color.rawValue)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected && isAvailable
                                     ? Color.white : Color.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Interaction rows

    private func toggleRow(icon: String,
                            label: String,
                            color: Color,
                            isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(label)
                    .foregroundStyle(Color.white)
            }
        }
        .tint(color)
        .listRowBackground(Color.white.opacity(0.07))
    }

    private var sensitivityRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "dial.medium")
                    .foregroundStyle(Color.orange)
                    .frame(width: 28)
                Text("Wheel Sensitivity")
                    .foregroundStyle(Color.white)
                Spacer()
                Text(sensitivityLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            Slider(value: $appSettings.wheelSensitivity, in: 0.5...2.0, step: 0.25)
                .tint(Color.orange)
                .padding(.leading, 40)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.white.opacity(0.07))
    }

    private var sensitivityLabel: String {
        switch appSettings.wheelSensitivity {
        case ..<0.75:  return "Slow"
        case ..<1.25:  return "Default"
        case ..<1.75:  return "Fast"
        default:       return "Very Fast"
        }
    }

    // MARK: - Music source rows

    private var streamingRow: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundStyle(Color.pink)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text("Streaming Library")
                    .foregroundStyle(Color.white)
                if !purchaseManager.hasFullAccess {
                    Text("Full access required")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.yellow.opacity(0.8))
                }
            }
            Spacer()
            if purchaseManager.hasFullAccess {
                statusBadge(text: authStatusText,
                            color: playerVM.musicAuthStatus == .authorized ? .green : .orange)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.yellow.opacity(0.7))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard purchaseManager.hasFullAccess else { showPaywall = true; return }
            if playerVM.musicAuthStatus != .authorized {
                Task { await playerVM.requestMusicKitAuthorization() }
            }
        }
        .listRowBackground(Color.white.opacity(0.07))
    }

    private var localLibraryRow: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(Color.yellow)
                .frame(width: 28)
            Text("Local Music Library")
                .foregroundStyle(Color.white)
            Spacer()
            statusBadge(text: playerVM.localAuthGranted ? "Connected" : "Tap to Allow",
                        color: playerVM.localAuthGranted ? .green : .orange)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !playerVM.localAuthGranted { playerVM.requestLocalLibraryAccess() }
        }
        .listRowBackground(Color.white.opacity(0.07))
    }

    // MARK: - Helpers

    private var authStatusText: String {
        switch playerVM.musicAuthStatus {
        case .authorized:    return "Connected"
        case .denied:        return "Denied"
        case .restricted:    return "Restricted"
        case .notDetermined: return "Tap to Allow"
        @unknown default:    return "Unknown"
        }
    }

    private func labelRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 28)
            Text(label).foregroundStyle(Color.white)
            Spacer()
            Text(value)
                .foregroundStyle(Color.white.opacity(0.5))
                .font(.system(size: 13))
        }
        .listRowBackground(Color.white.opacity(0.07))
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .cornerRadius(10)
    }
}

#Preview {
    SettingsView()
        .environmentObject(MusicPlayerViewModel())
        .environmentObject(PurchaseManager())
        .environmentObject(AppSettings())
}
