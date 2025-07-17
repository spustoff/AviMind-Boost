import SwiftUI

class SpeedTestViewModel: ObservableObject {
    enum State {
        case waiting, ready, signal, result, streakInProgress, streakSummary
    }
    enum DelayMode {
        case random, fixed
    }
    @Published var state: State = .waiting
    @Published var reactionTime: Int = 0
    @Published var showCountdown: Bool = false
    @Published var isStreakMode: Bool = false
    @Published var streakResults: [Int] = []
    @Published var streakTestIndex: Int = 0
    @Published var streakSummary: (average: Int, best: Int, deviation: Int)? = nil
    @Published var streakLength: Int = 5
    @Published var delayMode: DelayMode = .random
    private var signalTime: Date?
    private var timer: Timer?
    private var delay: TimeInterval = 0
    private var settings: AppSettings = AppSettings.load()
    private let fixedDelay: TimeInterval = 2.0
    
    func loadSettings() {
        settings = AppSettings.load()
    }
    
    func startTest() {
        if isStreakMode {
            streakResults = []
            streakTestIndex = 0
            state = .streakInProgress
            startStreakTest()
        } else {
            state = .ready
            showCountdown = settings.showCountdown
            let countdown = settings.showCountdown ? 3.0 : 0.0
            DispatchQueue.main.asyncAfter(deadline: .now() + countdown) { [weak self] in
                guard let self = self else { return }
                let delay = self.delayMode == .random ? Double.random(in: 1...5) : self.fixedDelay
                self.beginDelay(delay: delay)
            }
        }
    }
    
    private func startStreakTest() {
        showCountdown = settings.showCountdown
        let countdown = settings.showCountdown ? 3.0 : 0.0
        DispatchQueue.main.asyncAfter(deadline: .now() + countdown) { [weak self] in
            guard let self = self else { return }
            let delay = self.delayMode == .random ? Double.random(in: 1...5) : self.fixedDelay
            self.beginDelay(delay: delay, streak: true)
        }
    }
    
    private func beginDelay(delay: TimeInterval, streak: Bool = false) {
        showCountdown = false
        self.delay = delay
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.signalTime = Date()
            if streak {
                self?.state = .streakInProgress
            } else {
                self?.state = .signal
            }
            if self?.settings.vibrationEnabled == true {
                VibrationManager.vibrate()
            }
        }
    }
    
    func recordReaction() {
        guard let signalTime = signalTime else { return }
        let reaction = Int(Date().timeIntervalSince(signalTime) * 1000)
        reactionTime = reaction
        if isStreakMode {
            streakResults.append(reaction)
            streakTestIndex += 1
            if streakLength < 0 || streakTestIndex < streakLength {
                startStreakTest()
            } else {
                computeStreakSummary()
                state = .streakSummary
                for (idx, r) in streakResults.enumerated() {
                    HistoryViewModel.saveReaction(time: r, mode: .streak, delay: delay, countdown: settings.showCountdown, vibration: settings.vibrationEnabled, theme: settings.buttonTheme, streakIndex: idx, streakScores: streakResults)
                }
            }
        } else {
            HistoryViewModel.saveReaction(time: reaction, mode: .normal, delay: delay, countdown: settings.showCountdown, vibration: settings.vibrationEnabled, theme: settings.buttonTheme)
            state = .result
        }
    }
    
    func reset() {
        timer?.invalidate()
        if isStreakMode {
            state = .waiting
            streakResults = []
            streakTestIndex = 0
            streakSummary = nil
        } else {
            state = .waiting
            reactionTime = 0
            showCountdown = false
        }
    }
    
    func toggleStreakMode() {
        isStreakMode.toggle()
        reset()
    }
    
    private func computeStreakSummary() {
        guard !streakResults.isEmpty else { return }
        let avg = streakResults.reduce(0, +) / streakResults.count
        let best = streakResults.min() ?? 0
        let mean = Double(avg)
        let dev = Int(sqrt(streakResults.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(streakResults.count)))
        streakSummary = (avg, best, dev)
    }
    
    // Statistics for single test
    var bestResult: Int? {
        let history = HistoryViewModel.loadStatic()
        return history.map { $0.time }.min()
    }
    var averageResult: Int? {
        let history = HistoryViewModel.loadStatic()
        guard !history.isEmpty else { return nil }
        return history.map { $0.time }.reduce(0, +) / history.count
    }
    var deviation: Int? {
        let history = HistoryViewModel.loadStatic()
        guard !history.isEmpty else { return nil }
        let mean = Double(averageResult ?? 0)
        return Int(sqrt(history.map { pow(Double($0.time) - mean, 2) }.reduce(0, +) / Double(history.count)))
    }
} 