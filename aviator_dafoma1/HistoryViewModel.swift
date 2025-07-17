import SwiftUI

enum ReactionMode: String, Codable { case normal, streak }

struct ReactionResult: Codable, Identifiable {
    let id: UUID
    let time: Int
    let timestamp: Date
    let mode: ReactionMode
    let delay: Double
    let countdown: Bool
    let vibration: Bool
    let theme: String
    let streakIndex: Int? // If part of a streak, 0-based index
    let streakScores: [Int]? // If part of a streak, all scores in that series
    
    // For migration from old data
    init(id: UUID, time: Int, timestamp: Date, mode: ReactionMode = .normal, delay: Double = 0, countdown: Bool = false, vibration: Bool = false, theme: String = "Green", streakIndex: Int? = nil, streakScores: [Int]? = nil) {
        self.id = id
        self.time = time
        self.timestamp = timestamp
        self.mode = mode
        self.delay = delay
        self.countdown = countdown
        self.vibration = vibration
        self.theme = theme
        self.streakIndex = streakIndex
        self.streakScores = streakScores
    }
}

class HistoryViewModel: ObservableObject {
    @Published var results: [ReactionResult] = []
    var bestTime: Int? { results.map { $0.time }.min() }
    private static let historyKey = "reaction_history"
    private static let maxResults = 20
    
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: Self.historyKey),
           let decoded = try? JSONDecoder().decode([ReactionResult].self, from: data) {
            results = decoded
        } else if let data = UserDefaults.standard.data(forKey: Self.historyKey),
                  let oldDecoded = try? JSONDecoder().decode([OldReactionResult].self, from: data) {
            // Migrate old data
            results = oldDecoded.map { old in
                ReactionResult(id: old.id, time: old.time, timestamp: old.timestamp)
            }
        }
    }
    
    static func saveReaction(time: Int, mode: ReactionMode = .normal, delay: Double = 0, countdown: Bool = false, vibration: Bool = false, theme: String = "Green", streakIndex: Int? = nil, streakScores: [Int]? = nil) {
        var current = Self.loadStatic()
        let new = ReactionResult(id: UUID(), time: time, timestamp: Date(), mode: mode, delay: delay, countdown: countdown, vibration: vibration, theme: theme, streakIndex: streakIndex, streakScores: streakScores)
        current.insert(new, at: 0)
        if current.count > maxResults { current = Array(current.prefix(maxResults)) }
        if let data = try? JSONEncoder().encode(current) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    func clearHistory() {
        results = []
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }
    
    static func loadStatic() -> [ReactionResult] {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([ReactionResult].self, from: data) {
            return decoded
        }
        return []
    }
}

// For migration from old data
private struct OldReactionResult: Codable, Identifiable {
    let id: UUID
    let time: Int
    let timestamp: Date
} 