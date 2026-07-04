import SwiftUI

/// Elegant onboarding shown when Zen Browser is not installed.
struct OnboardingView: View {
    let onDownload: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Zen Browser Required")
                        .font(.title3.weight(.semibold))
                    Text("ZenShelf discovers Essentials from Zen Browser.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                onboardingStep(number: 1, text: "Download and install Zen Browser")
                onboardingStep(number: 2, text: "Pin your favorite sites as Essentials")
                onboardingStep(number: 3, text: "Return here — ZenShelf syncs automatically")
            }

            HStack {
                Button("Not Now") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Get Zen Browser") {
                    onDownload()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 380)
        .background(.regularMaterial)
        .animation(DesignTokens.motionAnimation(reduceMotion: reduceMotion), value: reduceMotion)
    }

    private func onboardingStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
                .background(Circle().fill(.quaternary))
                .accessibilityHidden(true)

            Text(text)
                .font(.body)
        }
        .accessibilityElement(children: .combine)
    }
}