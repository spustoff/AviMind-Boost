import SwiftUI

struct ProgressAnalyticsView: View {
    @State private var history: [ReactionResult] = HistoryViewModel.loadStatic()
    
    // Group by day
    var groupedByDay: [(date: Date, times: [Int])] {
        let grouped = Dictionary(grouping: history) { Calendar.current.startOfDay(for: $0.timestamp) }
        return grouped.keys.sorted().map { day in (day, grouped[day]!.map { $0.time }) }
    }
    var dailyAverages: [(date: Date, avg: Double)] {
        groupedByDay.map { ($0.date, Double($0.times.reduce(0, +)) / Double($0.times.count)) }
    }
    var best: Int? { history.map { $0.time }.min() }
    var worst: Int? { history.map { $0.time }.max() }
    var avg: Int? {
        guard !history.isEmpty else { return nil }
        return history.map { $0.time }.reduce(0, +) / history.count
    }
    var total: Int { history.count }
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("Progress")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .padding(.top, 8)
                    .padding(.leading, 20)
                Spacer(minLength: 0)
                ScrollView {
                    VStack(spacing: 24) {
                        // Chart
                        if history.count >= 3 {
                            ProgressLineChart(data: history.map { Double($0.time) })
                                .frame(height: 180)
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                        } else {
                            // Placeholder chart
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.theme.secondaryBackground)
                                    .frame(height: 180)
                                Text("Not enough data for chart yet.")
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                        // Stats
                        HStack(spacing: 24) {
                            StatBox(title: "Total", value: "\(total)", color: .white)
                            StatBox(title: "Best", value: best != nil ? "\(best!) ms" : "-", color: Color.theme.green)
                            StatBox(title: "Worst", value: worst != nil ? "\(worst!) ms" : "-", color: Color.theme.red)
                            StatBox(title: "Avg", value: avg != nil ? "\(avg!) ms" : "-", color: Color.theme.accent)
                        }
                        .padding(.horizontal, 12)
                        // Insights (placeholder)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Insights")
                                .font(.headline)
                                .foregroundColor(Color.theme.accent)
                            if total < 5 {
                                Text("Complete more tests to unlock insights!")
                                    .foregroundColor(.gray)
                            } else {
                                Text("Your last 5 attempts were \(last5Delta) ms above your average.")
                                    .foregroundColor(.white)
                                Text("You’re fastest on \(bestDayString). Keep it up!")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Placeholder for App Store compliance
                        if history.isEmpty {
                            Text("No progress yet. Try a speed test!")
                                .foregroundColor(.gray)
                                .padding(.top, 32)
                        }
                    }
                    .padding(.top, 8)
                }
                Spacer()
            }
        }
    }
    // Insights helpers
    var last5Delta: Int {
        guard let avg = avg, history.count >= 5 else { return 0 }
        let last5 = history.prefix(5).map { $0.time }
        return last5.reduce(0, +) / 5 - avg
    }
    var bestDayString: String {
        guard let best = best else { return "-" }
        let bestEntry = history.first { $0.time == best }
        guard let date = bestEntry?.timestamp else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(12)
    }
}

struct ProgressLineChart: View {
    let data: [Double]
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
            .stroke(Color.theme.green, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            // Dots
            ForEach(points.indices, id: \.self) { i in
                Circle()
                    .fill(Color.theme.accent)
                    .frame(width: 8, height: 8)
                    .position(points[i])
            }
        }
    }
}

#Preview {
    ProgressAnalyticsView()
} 
