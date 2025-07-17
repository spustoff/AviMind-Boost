import SwiftUI

struct AppSettings: Codable {
    var vibrationEnabled: Bool = true
    var showCountdown: Bool = true
    var buttonTheme: String = "Green" // or "Amber"
    static let settingsKey = "app_settings"
    
    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return AppSettings()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: AppSettings.settingsKey)
        }
    }
    
    static func reset() {
        UserDefaults.standard.removeObject(forKey: settingsKey)
    }
}

class SettingsViewModel: ObservableObject {
    @Published var vibrationEnabled: Bool {
        didSet { save() }
    }
    @Published var showCountdown: Bool {
        didSet { save() }
    }
    @Published var buttonTheme: String {
        didSet { save() }
    }
    
    init() {
        let settings = AppSettings.load()
        vibrationEnabled = settings.vibrationEnabled
        showCountdown = settings.showCountdown
        buttonTheme = settings.buttonTheme
    }
    
    private func save() {
        let settings = AppSettings(vibrationEnabled: vibrationEnabled, showCountdown: showCountdown, buttonTheme: buttonTheme)
        settings.save()
    }
    
    func resetAllData() {
        AppSettings.reset()
        HistoryViewModel().clearHistory()
        vibrationEnabled = true
        showCountdown = true
        buttonTheme = "Green"
    }
} 