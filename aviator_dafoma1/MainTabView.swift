import SwiftUI
import Foundation

struct MainTabView: View {
    init() {
        UITabBar.appearance().barTintColor = UIColor(Color.theme.background)
    }
    var body: some View {
        TabView {
            SpeedTestView()
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Speed Test")
                }
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            DailyChallengeView()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Daily Challenge")
                }
            TipsTabView()
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Tips")
                }
            ProgressAnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Progress")
                }
//            SettingsView()
//                .tabItem {
//                    Image(systemName: "gearshape.fill")
//                    Text("Settings")
//                }
        }
        .accentColor(Color.theme.accent)
        .background(Color.theme.background)
    }
}

// MARK: - Daily Challenge with Progress
struct DailyChallengeView: View {
    @State private var history: [ReactionResult] = HistoryViewModel.loadStatic()
    @State private var completedToday: Bool = false
    @State private var progress: Int = 0
    @State private var required: Int = 0
    @State private var challengeText: String = ""
    @State private var challengeType: ChallengeType = .underTime
    @State private var challengeTarget: Int = 250
    @State private var challengeCount: Int = 3
    @State private var showTips: Bool = false
    @State private var showConfetti: Bool = false
    @State private var completedHistory: [String] = []
    let motivationalQuotes = [
        "Small steps every day lead to big results.",
        "You are your only limit.",
        "Stay focused and never give up!",
        "Progress, not perfection.",
        "Every challenge is an opportunity to grow.",
        "Believe in yourself and all that you are.",
        "Discipline is the bridge between goals and accomplishment.",
        "Success is the sum of small efforts repeated day in and day out."
    ]
    var todayQuote: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return motivationalQuotes[day % motivationalQuotes.count]
    }
    enum ChallengeType { case underTime, streak, average, share }

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Daily Challenge")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 32)
                // Motivational quote
                Text("\"\(todayQuote)\"")
                    .font(.body.italic())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                Text(challengeText)
                    .font(.title2)
                    .foregroundColor(Color.theme.accent)
                    .multilineTextAlignment(.center)
                    .padding()
                if completedToday {
                    Label("Completed!", systemImage: "checkmark.seal.fill")
                        .font(.title2.bold())
                        .foregroundColor(Color.theme.green)
                        .padding(.top, 8)
                        .onAppear {
                            if !showConfetti {
                                withAnimation(.spring()) {
                                    
                                    showConfetti = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    withAnimation(.spring()) {
                                        
                                        showConfetti = false
                                    }
                                }
                            }
                            // Save to completed history if not already present
                            let today = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
                            let entry = "\(today): \(challengeText)"
                            if !completedHistory.contains(entry) {
                                completedHistory.insert(entry, at: 0)
                                saveCompletedHistory()
                            }
                        }
                        if showConfetti {
                            ConfettiView()
                                .frame(height: 120)
                        }
                } else {
                    ProgressView(value: Double(progress), total: Double(required))
                        .accentColor(Color.theme.accent)
                        .frame(height: 16)
                        .padding(.horizontal, 32)
                    Text("Progress: \(progress)/\(required)")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                // Button to view tips
                Button(action: { showTips = true }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(Color.theme.accent)
                        Text("View Tips & Insights")
                            .foregroundColor(.white)
                    }
                    .padding(10)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(10)
                }
                .sheet(isPresented: $showTips) {
                    TipsTabView()
                }
                // Completed challenge history
                if !completedHistory.isEmpty {
                    VStack(alignment: .center, spacing: 6) {
                        Text("Completed Challenges")
                            .font(.headline)
                            .foregroundColor(Color.theme.accent)
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(completedHistory.prefix(7), id: \.self) { entry in
                                    Text(entry)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 2)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                    .padding(.horizontal, 8)
                }
                Spacer()
                Text("Come back tomorrow for a new challenge!")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .onAppear(perform: setupChallenge)
        .onAppear(perform: loadCompletedHistory)
    }

    func setupChallenge() {
        history = HistoryViewModel.loadStatic()
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        // Rotate challenge type by day
        switch day % 4 {
        case 0:
            challengeType = .underTime
            challengeTarget = 250
            challengeCount = 3
            challengeText = "Get 3 reaction times under 250ms today!"
            required = challengeCount
            progress = history.filter { Calendar.current.isDateInToday($0.timestamp) && $0.time < challengeTarget }.count
            completedToday = progress >= required
        case 1:
            challengeType = .streak
            challengeCount = 5
            challengeText = "Complete 5 speed tests today."
            required = challengeCount
            progress = history.filter { Calendar.current.isDateInToday($0.timestamp) }.count
            completedToday = progress >= required
        case 2:
            challengeType = .average
            challengeTarget = 300
            challengeText = "Average under 300ms in today's speed tests (min 3)."
            let todayResults = history.filter { Calendar.current.isDateInToday($0.timestamp) }
            required = 3
            if todayResults.count >= required {
                let avg = todayResults.map { $0.time }.reduce(0, +) / todayResults.count
                progress = todayResults.count
                completedToday = avg < challengeTarget
                if completedToday { progress = required }
            } else {
                progress = todayResults.count
                completedToday = false
            }
        case 3:
            challengeType = .underTime
            challengeTarget = 200
            challengeCount = 1
            challengeText = "Beat your best time today: get under 200ms!"
            required = challengeCount
            progress = history.filter { Calendar.current.isDateInToday($0.timestamp) && $0.time < challengeTarget }.count
            completedToday = progress >= required
        default:
            break
        }
    }

    // Persistence for completed challenge history
    func saveCompletedHistory() {
        UserDefaults.standard.set(completedHistory, forKey: "completed_challenge_history")
    }
    func loadCompletedHistory() {
        if let arr = UserDefaults.standard.stringArray(forKey: "completed_challenge_history") {
            completedHistory = arr
        }
    }
}

// Simple confetti animation
struct ConfettiView: View {
    @State private var anim = false
    let colors: [Color] = [.yellow, .green, .blue, .pink, .orange, .purple, .red]
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<18) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 12, height: 12)
                    .position(x: CGFloat.random(in: 0...geo.size.width), y: anim ? geo.size.height : 0)
                    .opacity(0.7)
                    .animation(.easeInOut(duration: Double.random(in: 1.0...1.7)), value: anim)
            }
        }
        .onAppear { anim = true }
    }
}

#Preview {
    MainTabView()
} 
