//
//  DRAppApp.swift
//  DRApp
//
//  Created by Tarang Patel on 2026-05-18.
//

import SwiftUI
import SwiftData

@main
struct DRAppApp: App {
    @State private var appViewModel = AppViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyEntry.self,
            WeeklyReflection.self,
            UserProfile.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(appViewModel)
        }
        .modelContainer(sharedModelContainer)
    }
}
