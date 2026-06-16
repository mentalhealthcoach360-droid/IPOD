import SwiftUI
import MusicKit

struct SettingsView: View {
    @EnvironmentObject var playerVM: MusicPlayerViewModel

    var body: some View {
        ZStack {
            Color(white: 0.08).ignoresSafeArea()

            List {
                // iPod colour picker
                Section("iPod Colour") {
                    iPodColorPicker
                }
                .listSectionSpacing(8)

                // Music sources
                Section("Music Sources") {
                    appleMusicRow
                    localLibraryRow
                }
                .listSectionSpacing(8)

                // About
                Section("About") {
                    labelRow(icon: "app.badge", label: "Version", value: "1.0.0")
                    labelRow(icon: "purchased", label: "License", value: "Purchased")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .listRowBackground(Color.white.opacity(0.07))
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(white: 0.10), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Rows

    private var iPodColorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(iPodColor.allCases) { color in
                    colorSwatch(color)
                }
            }
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14))
    }

    private func colorSwatch(_ color: iPodColor) -> some View {
        let isSelected = playerVM.selectediPodColor == color
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                playerVM.selectediPodColor = color
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: color.bodyGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 2.5)
                            .frame(width: 46, height: 46)
                    }
                }
                Text(color.rawValue)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
    }

    private var appleMusicRow: some View {
        HStack {
            Image(systemName: "music.note")
                .foregroundStyle(Color.pink)
                .frame(width: 28)
            Text("Apple Music")
                .foregroundStyle(Color.white)
            Spacer()
            statusBadge(
                text: authStatusText,
                color: playerVM.musicAuthStatus == .authorized ? .green : .orange
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
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
            Text("Local Library")
                .foregroundStyle(Color.white)
            Spacer()
            statusBadge(
                text: playerVM.localAuthGranted ? "Connected" : "Tap to Allow",
                color: playerVM.localAuthGranted ? .green : .orange
            )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !playerVM.localAuthGranted {
                playerVM.requestLocalLibraryAccess()
            }
        }
        .listRowBackground(Color.white.opacity(0.07))
    }

    private var authStatusText: String {
        switch playerVM.musicAuthStatus {
        case .authorized:       return "Connected"
        case .denied:           return "Denied"
        case .restricted:       return "Restricted"
        case .notDetermined:    return "Tap to Allow"
        @unknown default:       return "Unknown"
        }
    }

    private func labelRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.white.opacity(0.6))
                .frame(width: 28)
            Text(label)
                .foregroundStyle(Color.white)
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
}
