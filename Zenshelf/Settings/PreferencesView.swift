import SwiftUI

/// ZenShelf preferences window.
struct PreferencesView: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        TabView {
            GeneralPreferencesPane(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AboutPreferencesPane()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 420, height: 280)
    }
}

private struct GeneralPreferencesPane: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .accessibilityLabel("Launch ZenShelf at login")

                Toggle("Sync Automatically", isOn: $settings.syncAutomatically)
                    .accessibilityLabel("Synchronize Essentials automatically")

                Toggle("Open on Login", isOn: $settings.openOnLogin)
                    .accessibilityLabel("Open ZenShelf on login")

                Toggle("Show Dock Icon", isOn: $settings.showDockIcon)
                    .accessibilityLabel("Show ZenShelf in the Dock")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct AboutPreferencesPane: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)

            Text("ZenShelf")
                .font(.title2.weight(.semibold))

            Text("The missing companion for Zen Browser.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Version \(Bundle.main.shortVersion)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

private extension Bundle {
    var shortVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}