import SwiftUI

struct AirplaneSignalView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.secondaryBackground)
                .frame(width: 180, height: 80)
            Image(systemName: "airplane")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(Color.theme.accent)
                .offset(x: animate ? 60 : -60, y: 0)
                .animation(Animation.easeInOut(duration: 0.7).repeatCount(1, autoreverses: false), value: animate)
                .onAppear { animate = true }
        }
    }
}

struct SpeedTestView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @StateObject private var historyViewModel = HistoryViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showClearAlert = false
    @State private var delayMode: DelayMode = .random
    
    enum DelayMode: String, CaseIterable, Identifiable {
        case random = "Random Delay"
        case fixed = "Fixed Delay"
        var id: String { self.rawValue }
        var model: SpeedTestViewModel.DelayMode {
            switch self {
            case .random: return .random
            case .fixed: return .fixed
            }
        }
        init(model: SpeedTestViewModel.DelayMode) {
            switch model {
            case .random: self = .random
            case .fixed: self = .fixed
            }
        }
    }
    private func pickerTextColor(for mode: DelayMode) -> Color {
        let selected = DelayMode(model: viewModel.delayMode)
        return selected == mode ? .black : .white
    }
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            VStack {
                
                Text("Speed Test")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 8)
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        Spacer(minLength: 0)
                        HStack {
                            Spacer()
                            VStack(spacing: 32) {
                                // Delay Mode Picker
                                HStack(spacing: 12) {
                                    
                                    HStack(spacing: 6) {
                                        Image(systemName: "gamecontroller.fill")
                                            .foregroundColor(Color.theme.accent)
                                        Text("Mode")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                    
                                    Spacer()
                                    
                                    CustomSegmentedPickerString(
                                        options: DelayMode.allCases.map { $0 },
                                        labels: DelayMode.allCases.map { $0.rawValue },
                                        selection: $delayMode
                                    )
                                    .onChange(of: delayMode) { newValue in
                                        viewModel.delayMode = newValue.model
                                    }
                                    .onAppear {
                                        delayMode = DelayMode(model: viewModel.delayMode)
                                    }
                                }
                                .padding(.bottom, 4)
                                // Vibration Feedback Toggle
                                Toggle(isOn: $settingsViewModel.vibrationEnabled) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "iphone.radiowaves.left.and.right")
                                            .foregroundColor(.white)
                                        Text("Enable Vibration Feedback")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.theme.green))
                                .padding(.bottom, 4)
                                // Streak Mode Toggle & Picker
                                HStack(spacing: 12) {
                                    Toggle(isOn: $viewModel.isStreakMode) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(Color.theme.accent)
                                            
                                            Text("Streak Mode")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: Color.theme.accent))
                                    if viewModel.isStreakMode {
                                        CustomSegmentedPicker(
                                            options: [3, 5, 10],
                                            labels: ["3", "5", "10"],
                                            selection: $viewModel.streakLength
                                        )
                                    }
                                }
                                // Streak Progress Bar
                                if viewModel.isStreakMode && (viewModel.state == .streakInProgress || viewModel.state == .streakSummary) {
                                    VStack(spacing: 4) {
                                        if viewModel.streakLength > 0 {
                                            AnimatedStreakProgressBar(current: viewModel.streakTestIndex, total: viewModel.streakLength)
                                                .frame(height: 12)
                                                .padding(.horizontal, 24)
                                            Text("Test \(viewModel.streakTestIndex + 1) of \(viewModel.streakLength)")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        } else {
                                            AnimatedStreakProgressBar(current: viewModel.streakTestIndex, total: max(viewModel.streakTestIndex + 1, 5))
                                                .frame(height: 12)
                                                .padding(.horizontal, 24)
                                            Text("Endless Streak: \(viewModel.streakTestIndex + 1) in a row")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                // Main Test UI
                                if viewModel.state == .waiting {
                                    AnimatedAppleStyleButton(
                                        title: viewModel.isStreakMode ? "Start Streak" : "Start",
                                        color: Color.theme.green,
                                        action: { withAnimation(.spring()) {
                                            
                                            viewModel.startTest()
                                        } }
                                    )
                                    .frame(maxWidth: 320)
                                    .modifier(PulseOnAppear())
                                    // Show info message after 3+ plays, before full analytics (5+)
                                    if viewModel.completedTestsCount >= 3 && viewModel.completedTestsCount < 5 {
                                        Text("Great job! Keep going to unlock detailed progress analytics.")
                                            .font(.subheadline)
                                            .foregroundColor(Color.theme.accent)
                                            .padding(.top, 16)
                                            .transition(.opacity)
                                    }
                                    // Progress analytics summary after 5+ tests
                                    if viewModel.completedTestsCount >= 2 {
                                        SpeedTestProgressSummary()
                                            .padding(.top, 24)
                                            .transition(.move(edge: .bottom).combined(with: .opacity))
                                            .animation(.spring(), value: viewModel.completedTestsCount)
                                    }
                                } else if viewModel.state == .ready {
                                    Text(viewModel.showCountdown ? "Get Ready..." : "Wait for it...")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                        .padding()
                                } else if viewModel.state == .signal || viewModel.state == .streakInProgress {
                                    VStack(spacing: 16) {
                                        AirplaneSignalViewAnimated()
                                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                                            .animation(.easeInOut(duration: 0.5), value: viewModel.state)
                                        AnimatedAppleStyleButton(
                                            title: "TAP!",
                                            color: Color.theme.red,
                                            action: { viewModel.recordReaction() }
                                        )
                                        .frame(maxWidth: 320)
                                    }
                                } else if viewModel.state == .result {
                                    VStack(spacing: 20) {
                                        Text("Reaction Time")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .transition(.opacity.combined(with: .scale))
                                            .animation(.easeOut(duration: 0.5), value: viewModel.state)
                                        Text("\(viewModel.reactionTime) ms")
                                            .font(.system(size: 54, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.theme.green)
                                            .transition(.scale)
                                            .animation(.spring(), value: viewModel.state)
                                        // Statistics Panel
                                        if let best = viewModel.bestResult, let avg = viewModel.averageResult, let dev = viewModel.deviation {
                                            VStack(spacing: 6) {
                                                HStack {
                                                    Text("Best:")
                                                        .foregroundColor(.gray)
                                                    Text("\(best) ms")
                                                        .foregroundColor(Color.theme.green)
                                                }
                                                HStack {
                                                    Text("Average:")
                                                        .foregroundColor(.gray)
                                                    Text("\(avg) ms")
                                                        .foregroundColor(.white)
                                                }
                                                HStack {
                                                    Text("Deviation:")
                                                        .foregroundColor(.gray)
                                                    Text("\(dev) ms")
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .font(.subheadline)
                                            .padding(8)
                                            .background(Color.theme.secondaryBackground)
                                            .cornerRadius(12)
                                        }
                                        AnimatedAppleStyleButton(
                                            title: "Try Again",
                                            color: Color.theme.accent,
                                            action: { viewModel.reset() }
                                        )
                                        .frame(maxWidth: 320)
                                    }
                                } else if viewModel.state == .streakSummary, let summary = viewModel.streakSummary {
                                    VStack(spacing: 20) {
                                        Text("Streak Complete!")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                        Text("Results:")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        VStack(spacing: 6) {
                                            HStack {
                                                Text("Best:")
                                                    .foregroundColor(.gray)
                                                Text("\(summary.best) ms")
                                                    .foregroundColor(Color.theme.green)
                                            }
                                            HStack {
                                                Text("Average:")
                                                    .foregroundColor(.gray)
                                                Text("\(summary.average) ms")
                                                    .foregroundColor(.white)
                                            }
                                            HStack {
                                                Text("Deviation:")
                                                    .foregroundColor(.gray)
                                                Text("\(summary.deviation) ms")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .font(.subheadline)
                                        .padding(8)
                                        .background(Color.theme.secondaryBackground)
                                        .cornerRadius(12)
                                        AnimatedAppleStyleButton(
                                            title: "Done",
                                            color: Color.theme.accent,
                                            action: { viewModel.reset() }
                                        )
                                        .frame(maxWidth: 320)
                                    }
                                }
                            }
                            Spacer()
                        }
                        // --- New: Compact History Section ---
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Recent Results")
                                    .font(.headline)
                                    .foregroundColor(Color.theme.accent)
                                Spacer()
                                Button(action: { showClearAlert = true }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(Color.theme.red)
                                        .padding(8)
                                        .background(Color.theme.secondaryBackground)
                                        .clipShape(Circle())
                                }
                                .alert(isPresented: $showClearAlert) {
                                    Alert(
                                        title: Text("Clear History?"),
                                        message: Text("This will remove all your speed test results."),
                                        primaryButton: .destructive(Text("Clear")) {
                                            historyViewModel.clearHistory()
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(historyViewModel.results.prefix(10)) { result in
                                        VStack(alignment: .center, spacing: 4) {
                                            Text("\(result.time) ms")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(result.timestamp, style: .time)
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        .padding(8)
                                        .background(Color.theme.secondaryBackground)
                                        .cornerRadius(10)
                                    }
                                    if historyViewModel.results.isEmpty {
                                        Text("No results yet.")
                                            .foregroundColor(.gray)
                                            .padding(.top, 8)
                                    }
                                }
                                .padding(.horizontal, 8)
                            }
                            // Simple chart of last 10 results
                            if historyViewModel.results.count > 1 {
                                AnimatedProgressLineChart(data: historyViewModel.results.prefix(10).map { Double($0.time) }.reversed())
                                    .frame(height: 60)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.top, 8)
                        .onAppear { historyViewModel.loadHistory() }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            
        }
    }
}

#Preview {
    SpeedTestView()
} 

struct AppleStyleButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(
                    LinearGradient(gradient: Gradient(colors: [color.opacity(0.95), color.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .cornerRadius(18)
                .shadow(color: color.opacity(0.25), radius: 12, y: 6)
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
} 

extension SpeedTestViewModel {
    var completedTestsCount: Int {
        HistoryViewModel.loadStatic().count
    }
}

struct SpeedTestProgressSummary: View {
    let history: [ReactionResult] = HistoryViewModel.loadStatic()
    var best: Int? { history.map { $0.time }.min() }
    var worst: Int? { history.map { $0.time }.max() }
    var avg: Int? {
        guard !history.isEmpty else { return nil }
        return history.map { $0.time }.reduce(0, +) / history.count
    }
    var total: Int { history.count }
    var miniChartData: [Double] { history.suffix(10).map { Double($0.time) } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
                .foregroundColor(Color.theme.accent)
            HStack(spacing: 18) {
                StatBox(title: "Total", value: "\(total)", color: .white)
                StatBox(title: "Best", value: best != nil ? "\(best!) ms" : "-", color: Color.theme.green)
                StatBox(title: "Worst", value: worst != nil ? "\(worst!) ms" : "-", color: Color.theme.red)
                StatBox(title: "Avg", value: avg != nil ? "\(avg!) ms" : "-", color: Color.theme.accent)
            }
            .padding(.horizontal, 2)
            if miniChartData.count > 1 {
                AnimatedProgressLineChart(data: miniChartData)
                    .frame(height: 60)
                    .padding(.horizontal, 2)
            }
        }
        .padding()
        .background(Color.theme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.theme.accent.opacity(0.10), radius: 6, y: 2)
    }
} 

struct PulseOnAppear: ViewModifier {
    @State private var pulse = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 1.04 : 1.0)
            .shadow(color: Color.theme.green.opacity(pulse ? 0.25 : 0.10), radius: pulse ? 18 : 8)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

struct AirplaneSignalViewAnimated: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.secondaryBackground)
                .frame(width: 180, height: 80)
            Image(systemName: "airplane")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(Color.theme.accent)
                .offset(x: animate ? 60 : -60, y: animate ? -18 : 0)
                .opacity(animate ? 0.7 : 1)
                .rotationEffect(.degrees(animate ? 18 : 0))
                .animation(Animation.easeInOut(duration: 0.8), value: animate)
                .onAppear { animate = true }
        }
    }
} 

struct AnimatedProgressLineChart: View {
    let data: [Double]
    @State private var animProgress: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            let maxY = (data.max() ?? 1)
            let minY = (data.min() ?? 0)
            let points = data.enumerated().map { (i, v) in
                CGPoint(
                    x: geo.size.width * CGFloat(i) / CGFloat(max(data.count - 1, 1)),
                    y: geo.size.height - ((CGFloat(v - minY) / CGFloat(maxY - minY + 1e-6)) * geo.size.height)
                )
            }
            Path { path in
                guard points.count > 1 else { return }
                path.move(to: points[0])
                for pt in points.dropFirst() {
                    path.addLine(to: pt)
                }
            }
            .trim(from: 0, to: animProgress)
            .stroke(Color.theme.green, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .animation(.easeOut(duration: 1.0), value: animProgress)
            // Dots
            ForEach(points.indices, id: \.self) { i in
                if CGFloat(i) / CGFloat(max(points.count - 1, 1)) <= animProgress {
                    Circle()
                        .fill(Color.theme.accent)
                        .frame(width: 8, height: 8)
                        .position(points[i])
                        .opacity(Double(animProgress))
                        .animation(.easeOut(duration: 0.7).delay(Double(i) * 0.05), value: animProgress)
                }
            }
        }
        .onAppear {
            animProgress = 0
            withAnimation(.easeOut(duration: 1.0)) {
                animProgress = 1
            }
        }
    }
} 

struct AnimatedAppleStyleButton: View {
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
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(
                    LinearGradient(gradient: Gradient(colors: [color.opacity(0.95), color.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .cornerRadius(18)
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

struct AnimatedStreakProgressBar: View {
    let current: Int
    let total: Int
    @State private var animValue: CGFloat = 0
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.theme.secondaryBackground)
                Capsule()
                    .fill(Color.theme.accent)
                    .frame(width: geo.size.width * CGFloat(min(CGFloat(current), CGFloat(total))) / CGFloat(max(total, 1)) * animValue)
                    .animation(.easeOut(duration: 0.6), value: animValue)
            }
        }
        .onAppear {
            animValue = 0
            withAnimation(.easeOut(duration: 0.6)) {
                animValue = 1
            }
        }
    }
} 

// MARK: - Custom Segmented Picker
struct CustomSegmentedPicker: View {
    let options: [Int]
    let labels: [String]
    @Binding var selection: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(options.enumerated()), id: \ .offset) { idx, value in
                Button(action: { selection = value }) {
                    Text(labels[idx])
                        .font(.subheadline.bold())
                        .foregroundColor(selection == value ? .white : .gray)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(selection == value ? Color.theme.accent : Color.theme.secondaryBackground)
                        .cornerRadius(8)
                        .animation(.easeInOut(duration: 0.15), value: selection == value)
                }
            }
        }
        .padding(4)
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(10)
    }
} 

// MARK: - Custom Segmented Picker for String Enum
struct CustomSegmentedPickerString<T: Hashable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    let options: [T]
    let labels: [String]
    @Binding var selection: T
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(options.enumerated()), id: \ .offset) { idx, value in
                Button(action: { selection = value }) {
                    Text(labels[idx])
                        .font(.subheadline.bold())
                        .foregroundColor(selection == value ? .white : .gray)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(selection == value ? Color.theme.accent : Color.theme.secondaryBackground)
                        .cornerRadius(8)
                        .animation(.easeInOut(duration: 0.15), value: selection == value)
                }
            }
        }
        .padding(4)
        .background(Color.theme.secondaryBackground.opacity(0.5))
        .cornerRadius(10)
    }
} 
