//
//  DRAppApp.swift
//  DRApp
//
//  Created by Tarang Patel on 2026-05-18.
//

import SwiftUI
import SwiftData
import os

private let logger = Logger(subsystem: "com.tarangp.DRApp", category: "DRAppApp")

@main
struct DRAppApp: App {
    @State private var appViewModel = AppViewModel()

    private static let schema = Schema([
        DailyEntry.self,
        WeeklyReflection.self,
        UserProfile.self
    ])

    let sharedModelContainer: ModelContainer
    /// True when the persistent store couldn't be opened and we fell back to an in-memory store.
    let dataStoreUnavailable: Bool

    init() {
        let persistentConfig = ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: Self.schema, configurations: [persistentConfig]) {
            sharedModelContainer = container
            dataStoreUnavailable = false
        } else {
            logger.error("Persistent ModelContainer failed to load — falling back to an in-memory store.")
            let fallbackConfig = ModelConfiguration(schema: Self.schema, isStoredInMemoryOnly: true)
            sharedModelContainer = try! ModelContainer(for: Self.schema, configurations: [fallbackConfig])
            dataStoreUnavailable = true
        }
    }

    var body: some Scene {
        WindowGroup {
            if dataStoreUnavailable {
                DataUnavailableView()
            } else {
                AppView()
                    .environment(appViewModel)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - DataUnavailableView

/// Shown in place of the app when the on-device store couldn't be opened,
/// so a corrupt store never turns into a launch crash.
private struct DataUnavailableView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text("Your reflections couldn't be loaded")
                .font(AppTheme.Fonts.headingSerif)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Try closing and reopening the app. If this keeps happening, your device storage may be low.")
                .font(AppTheme.Fonts.bodySerif)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, AppTheme.Layout.horizontalPadding)
        .appBackground()
    }
}
