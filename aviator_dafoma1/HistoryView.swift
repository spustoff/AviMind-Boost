import SwiftUI
import UIKit

// Custom modifier for placeholder color
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var searchText = ""
    @State private var selectedResult: ReactionResult? = nil
    @State private var showExporter = false
    @State private var csvURL: URL? = nil
    @State private var isExporting = false
    
    var filteredResults: [ReactionResult] {
        if searchText.isEmpty { return viewModel.results }
        return viewModel.results.filter { "\($0.time)".contains(searchText) }
    }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("History")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 8)
                    .padding(.leading, 20)
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        // Export & Search Bar
                        HStack {
                            Button(action: exportCSV) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Color.theme.accent)
                                    .padding(8)
                                    .background(Color.theme.secondaryBackground)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 8)
                            .accessibilityLabel("Export CSV")
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            ZStack(alignment: .leading) {
                                if searchText.isEmpty {
                                    Text("Search")
                                        .foregroundColor(.gray)
                                }
                                TextField("", text: $searchText)
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                        }
                        .padding(10)
                        .background(Color.theme.secondaryBackground)
                        .cornerRadius(14)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        // List
                        List {
                            if filteredResults.isEmpty {
                                ForEach(sampleHistory) { result in
                                    HistorySampleRow(result: result)
                                }
                            } else {
                                ForEach(filteredResults) { result in
                                    Button(action: { selectedResult = result }) {
                                        HStack(spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(result.time == viewModel.bestTime ? Color.theme.green : Color.theme.secondaryBackground)
                                                    .frame(width: 44, height: 44)
                                                Image(systemName: result.time == viewModel.bestTime ? "bolt.fill" : "stopwatch")
                                                    .foregroundColor(result.time == viewModel.bestTime ? .white : Color.theme.accent)
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(result.time) ms")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text(result.timestamp, style: .time)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .listRowBackground(Color.theme.background)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.theme.background)
                        .padding(.top, 4)
                        HStack {
                            Spacer()
                            Button(action: { viewModel.clearHistory() }) {
                                Image(systemName: "trash")
                                    .foregroundColor(Color.theme.red)
                                    .padding(12)
                                    .background(Color.theme.secondaryBackground)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 8)
                        }
                    }
                    Spacer()
                }
                Spacer()
            }
            if isExporting {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView("Preparing CSV...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.theme.accent))
                    .foregroundColor(.white)
                    .padding(32)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(16)
            }
        }
        .sheet(isPresented: Binding(get: { showExporter && csvURL != nil }, set: { showExporter = $0 })) {
            if let url = csvURL {
                ActivityViewController(activityItems: [url]) {
                    showExporter = false
                    csvURL = nil
                    isExporting = false
                }
            }
        }
        .sheet(item: $selectedResult) { result in
            HistoryDetailModal(result: result, bestTime: viewModel.bestTime)
        }
        .onAppear { viewModel.loadHistory() }
    }
    // Sample data for empty state
    var sampleHistory: [ReactionResult] {
        [
            ReactionResult(id: UUID(), time: 250, timestamp: Date(), mode: .normal, delay: 2.1, countdown: true, vibration: true, theme: "Red"),
            ReactionResult(id: UUID(), time: 320, timestamp: Date().addingTimeInterval(-3600), mode: .normal, delay: 3.0, countdown: false, vibration: false, theme: "Red"),
            ReactionResult(id: UUID(), time: 210, timestamp: Date().addingTimeInterval(-7200), mode: .streak, delay: 1.7, countdown: true, vibration: true, theme: "Red", streakIndex: 1, streakScores: [210, 250, 320])
        ]
    }
    // CSV export logic
    func exportCSV() {
        isExporting = true
        DispatchQueue.global(qos: .userInitiated).async {
            let results = viewModel.results
            let header = "Time (ms),Date,Mode,Delay,Countdown,Vibration,Theme\n"
            let rows = results.map { r in
                "\(r.time),\(r.timestamp),\(r.mode.rawValue),\(r.delay),\(r.countdown),\(r.vibration),\(r.theme)"
            }
            let csv = header + rows.joined(separator: "\n")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("reaction_history.csv")
            try? csv.write(to: url, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                csvURL = url
                showExporter = true
                isExporting = false
            }
        }
    }
}

struct HistoryDetailModal: View, Identifiable {
    let id = UUID()
    let result: ReactionResult
    let bestTime: Int?
    @Environment(\.dismiss) var dismiss
    
    var isBest: Bool { bestTime == result.time }
    var body: some View {
        ZStack {
            Color(hex: "#1a1c1e").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Reaction Details")
                        .font(.title2.bold())
                        .foregroundColor(Color.theme.accent)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.theme.secondaryBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 8)
                Group {
                    HStack {
                        Text("Reaction Time:")
                            .foregroundColor(Color.theme.accent)
                        Text("\(result.time) ms")
                            .foregroundColor(isBest ? Color.theme.green : Color.theme.red)
                            .fontWeight(isBest ? .bold : .regular)
                    }
                    HStack {
                        Text("Date:")
                            .foregroundColor(Color.theme.accent)
                        Text(result.timestamp, style: .date)
                            .foregroundColor(.white)
                        Text(result.timestamp, style: .time)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("Mode:")
                            .foregroundColor(Color.theme.accent)
                        Text(result.mode == .streak ? "Streak" : "Normal")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Delay:")
                            .foregroundColor(Color.theme.accent)
                        Text(String(format: "%.1f sec", result.delay))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Countdown:")
                            .foregroundColor(Color.theme.accent)
                        Text(result.countdown ? "Yes" : "No")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Vibration:")
                            .foregroundColor(Color.theme.accent)
                        Text(result.vibration ? "Yes" : "No")
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Theme:")
                            .foregroundColor(Color.theme.accent)
                        Text(result.theme)
                            .foregroundColor(result.theme == "Green" ? Color.theme.green : Color.theme.accent)
                    }
                    if isBest {
                        Text("Quickest tap so far!")
                            .foregroundColor(Color.theme.green)
                            .fontWeight(.bold)
                    }
                }
                if result.mode == .streak, let idx = result.streakIndex, let scores = result.streakScores {
                    Divider().background(Color.theme.secondaryBackground)
                    Text("Streak Details")
                        .font(.headline)
                        .foregroundColor(Color.theme.accent)
                    Text("Attempt \(idx + 1) of \(scores.count)")
                        .foregroundColor(.white)
                    HStack(spacing: 8) {
                        ForEach(scores.indices, id: \.self) { i in
                            Text("\(scores[i])")
                                .padding(6)
                                .background(i == idx ? Color.theme.green : Color.theme.secondaryBackground)
                                .foregroundColor(i == idx ? .white : .gray)
                                .cornerRadius(8)
                        }
                    }
                }
                Spacer()
            }
            .padding(24)
        }
    }
}

#Preview {
    HistoryView()
} 

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    var onComplete: (() -> Void)? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HistorySampleRow: View {
    let result: ReactionResult
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(result.time == 210 ? Color.theme.green : Color.theme.secondaryBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: result.time == 210 ? "bolt.fill" : "stopwatch")
                    .foregroundColor(result.time == 210 ? .white : Color.theme.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.time) ms")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
} 
