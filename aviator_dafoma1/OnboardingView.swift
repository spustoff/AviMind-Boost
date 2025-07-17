import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var page = 0
    let totalPages = 7
    
    var body: some View {
        ZStack {
            Color(hex: "#0e0e0e").ignoresSafeArea()
            TabView(selection: $page) {
                OnboardingPage(
                    title: "Welcome to Aviator Speed Check",
                    subtitle: "Test your reaction. Train your focus. Track your progress.",
                    image: "airplane",
                    showSkip: true,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(0)
                OnboardingPage(
                    title: "Speed Test",
                    subtitle: "Tap 'Start', wait for the airplane, then tap as fast as you can! Try Normal or Streak mode.",
                    image: "bolt.fill",
                    showSkip: true,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(1)
                OnboardingPage(
                    title: "Focus Mode",
                    subtitle: "Use the Pomodoro timer to boost your concentration. Enjoy sound, vibration, and visual feedback.",
                    image: "timer",
                    showSkip: true,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(2)
                OnboardingPage(
                    title: "History & Stats",
                    subtitle: "All your results are saved. Tap any entry for detailed session data and stats.",
                    image: "clock.fill",
                    showSkip: true,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(3)
                OnboardingPage(
                    title: "Privacy & Local Data",
                    subtitle: "Your data stays on your device. No account, no tracking, no cloud sync.",
                    image: "lock.fill",
                    showSkip: true,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(4)
                OnboardingPage(
                    title: "Settings",
                    subtitle: "Configure vibration, delay range, countdown, and more in Settings.",
                    image: "gearshape.fill",
                    showSkip: true,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(5)
                OnboardingPage(
                    title: "Let’s Start!",
                    subtitle: "You’re ready to fly. Good luck!",
                    image: "checkmark.seal.fill",
                    showSkip: false,
                    page: $page,
                    totalPages: totalPages,
                    onFinish: { hasSeenOnboarding = true }
                ).tag(6)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        }
    }
}

struct OnboardingPage: View {
    let title: String
    let subtitle: String
    let image: String
    let showSkip: Bool
    @Binding var page: Int
    let totalPages: Int
    let onFinish: () -> Void
    @State private var isPressed = false
    @State private var glow = false
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Spacer()
                if showSkip {
                    Button("Skip") { page = totalPages - 1 }
                        .foregroundColor(Color.theme.red)
                        .padding(.trailing, 20)
                        .padding(.top, 8)
                }
            }
            Spacer()
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color.theme.accent)
                .padding(.bottom, 8)
                .scaleEffect(isPressed ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: isPressed)
            Text(title)
                .font(.title.bold())
                .foregroundColor(Color.theme.accent)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 5)
            Text(subtitle)
                .font(.body)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            if page == totalPages - 1 {
                AnimatedOnboardingButton(title: "Get Started", color: Color.theme.green, action: onFinish)
                    .padding(.horizontal)
            } else {
                AnimatedOnboardingButton(title: "Next", color: Color.theme.accent, action: { withAnimation(.spring()) { page += 1 } })
                    .padding(.horizontal)
            }
            Spacer(minLength: 24)
        }
        .background(Color(hex: "#0e0e0e"))
        .cornerRadius(24)
        .padding(.vertical, 24)
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
        .animation(.easeInOut(duration: 0.5), value: page)
    }
}

struct AnimatedOnboardingButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    @State private var glow = false
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                isPressed = false
                action()
            }
        }) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(gradient: Gradient(colors: [color.opacity(0.95), color.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .cornerRadius(16)
                .shadow(color: color.opacity(glow ? 0.45 : 0.18), radius: glow ? 18 : 8, y: 6)
                .scaleEffect(isPressed ? 0.93 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPressed)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glow = true
                    }
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
