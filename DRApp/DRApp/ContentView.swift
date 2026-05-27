//
//  ContentView.swift
//  DRApp
//
//  Created by Tarang Patel on 2026-05-18.
//

import SwiftUI
import SwiftData

// ContentView is retained for compatibility but the app entry point is AppView.
// See Views/AppView.swift for the root navigation.
struct ContentView: View {
    var body: some View {
        AppView()
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [DailyEntry.self, WeeklyReflection.self, UserProfile.self],
            inMemory: true
        )
        .environment(AppViewModel())
}
