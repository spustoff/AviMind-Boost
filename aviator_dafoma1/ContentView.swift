//
//  ContentView.swift
//  aviator_dafoma1
//
//  Created by Вячеслав on 7/16/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
        }
    }
}

#Preview {
    ContentView()
}
