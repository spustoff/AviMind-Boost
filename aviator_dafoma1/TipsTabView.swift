import SwiftUI

struct Tip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    var isRead: Bool = false
}

class TipsViewModel: ObservableObject {
    @Published var tips: [Tip] = [
        Tip(title: "How to improve your reaction speed", content: "Practice regularly, minimize distractions, and get enough sleep. Try Streak Mode for extra challenge!"),
        Tip(title: "Pomodoro technique basics", content: "Work for 25 minutes, then take a 5-minute break. Repeat. This helps maintain focus and avoid burnout."),
        Tip(title: "Benefits of focused attention", content: "Improved productivity, better memory, and less stress. Use Focus Mode to train your mind!"),
        Tip(title: "Set Clear Goals", content: "Before each session, write down what you want to accomplish. Clear goals boost motivation and focus."),
        Tip(title: "Eliminate Distractions", content: "Silence your phone, close unnecessary tabs, and let others know you’re focusing. Environment matters!"),
        Tip(title: "Use Short Breaks Wisely", content: "During breaks, stand up, stretch, or get some fresh air. Avoid screens to truly recharge."),
        Tip(title: "Track Your Progress", content: "Review your session history to see improvement over time. Celebrate your consistency!"),
        Tip(title: "Stay Hydrated", content: "Drink water regularly. Hydration helps maintain energy and concentration throughout the day."),
        Tip(title: "Practice Mindfulness", content: "Take a minute to breathe deeply before starting. Mindfulness can help you enter a focused state faster."),
        Tip(title: "Reward Yourself", content: "After a productive session, give yourself a small reward. Positive reinforcement builds good habits."),
    ]
    
    func markAsRead(_ tip: Tip) {
        if let idx = tips.firstIndex(where: { $0.id == tip.id }) {
            tips[idx].isRead = true
        }
    }
}

struct TipsTabView: View {
    @StateObject private var viewModel = TipsViewModel()
    @State private var appear = [Bool]()
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("Tips & Insights")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 8)
                    .padding(.leading, 20)
                Spacer(minLength: 0)
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(viewModel.tips.enumerated()), id: \.offset) { idx, tip in
                            TipCardView(tip: tip, isRead: tip.isRead)
                                .opacity(appear.count > idx && appear[idx] ? 1 : 0)
                                .offset(y: appear.count > idx && appear[idx] ? 0 : 40)
                                .animation(.easeOut(duration: 0.5).delay(Double(idx) * 0.13), value: appear.count > idx ? appear[idx] : false)
                                .onAppear {
                                    if appear.count <= idx { appear.append(false) }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.13) {
                                        if appear.count > idx { appear[idx] = true }
                                    }
                                }
                                .onTapGesture { viewModel.markAsRead(tip) }
                        }
                        // Placeholder for App Store compliance
                        if viewModel.tips.isEmpty {
                            TipCardView(tip: Tip(title: "How to improve your reaction speed", content: "Practice regularly, minimize distractions, and get enough sleep. Try Streak Mode for extra challenge!"), isRead: false)
                            TipCardView(tip: Tip(title: "Pomodoro technique basics", content: "Work for 25 minutes, then take a 5-minute break. Repeat. This helps maintain focus and avoid burnout."), isRead: false)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
    }
}

struct TipCardView: View {
    let tip: Tip
    let isRead: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tip.title)
                    .font(.headline)
                    .foregroundColor(Color.theme.accent)
                Spacer()
                if isRead {
                    Text("Read")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(4)
                        .background(Color.theme.secondaryBackground)
                        .cornerRadius(6)
                } else {
                    Text("New")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.theme.accent)
                        .cornerRadius(6)
                }
            }
            Text(tip.content)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.theme.accent.opacity(0.15), radius: 6, y: 2)
    }
}

#Preview {
    TipsTabView()
} 