import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 8)
                    .padding(.leading, 20)
                HStack {
                    Spacer()
                    VStack(spacing: 32) {
                        Toggle(isOn: $viewModel.vibrationEnabled) {
                            Label("Enable Vibration Feedback", systemImage: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color.theme.green))
                        Toggle(isOn: $viewModel.showCountdown) {
                            Label("Show Countdown Before Signal", systemImage: "timer")
                                .foregroundColor(.white)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: Color.theme.accent))
                        Button(action: { viewModel.resetAllData() }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Reset All Data")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.theme.red)
                            .cornerRadius(12)
                        }
                    }
                    Spacer()
                }
                .padding()
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    Text("About the App")
                        .font(.headline)
                        .foregroundColor(Color.theme.accent)
                    Text("Reflex Focus helps you improve your reaction speed and focus. All features are for productivity and wellness. No accounts, no tracking, all data stays on your device.")
                        .foregroundColor(.white)
                        .font(.subheadline)
                    Text("Support: support@reflexfocus.app")
                        .foregroundColor(Color.theme.red)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.theme.secondaryBackground)
                .cornerRadius(14)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.top, 16)
        }
    }
}

#Preview {
    SettingsView()
} 
