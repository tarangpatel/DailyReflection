import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyEntry.date) private var entries: [DailyEntry]

    @State private var vm = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {

                // Notifications
                settingsSection("Notifications") {
                    VStack(spacing: 1) {
                        Toggle(isOn: Binding(
                            get: { vm.notificationsEnabled },
                            set: { newValue in Task { await vm.setNotificationsEnabled(newValue) } }
                        )) {
                            Text("Daily reminder")
                                .font(AppTheme.Fonts.labelSans)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                        }
                        .tint(AppTheme.Colors.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                        if vm.notificationsEnabled {
                            Divider()
                                .background(AppTheme.Colors.divider)
                                .padding(.horizontal, 20)

                            DatePicker(
                                "Remind me at",
                                selection: Binding(
                                    get: { vm.reminderTime },
                                    set: { vm.updateReminderTime($0) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .font(AppTheme.Fonts.labelSans)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                }

                // Your Data
                settingsSection("Your Data") {
                    VStack(spacing: 1) {
                        // Export
                        exportButton

                        Divider()
                            .background(AppTheme.Colors.divider)
                            .padding(.horizontal, 20)

                        // Import
                        importButton
                    }
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                }

                // Privacy
                settingsSection("Privacy") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your entries are private.\nWe do not sell or share your data.")
                            .font(AppTheme.Fonts.bodySerif)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                }
            }
            .padding(.horizontal, AppTheme.Layout.horizontalPadding)
            .padding(.bottom, 40)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .appBackground()
        .fileImporter(
            isPresented: $vm.showImportFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            onCompletion: { result in
                switch result {
                case .success(let url):
                    Task {
                        await vm.importCSV(from: url, context: modelContext, existingEntries: entries)
                    }
                case .failure(let error):
                    vm.errorMessage = error.localizedDescription
                }
            }
        )
        .alert("Import complete", isPresented: $vm.showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(vm.importSuccessCount) \(vm.importSuccessCount == 1 ? "entry" : "entries") added.")
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Notifications are off", isPresented: $vm.showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications for Daily Reflection in Settings to turn on your daily reminder.")
        }
    }

    // MARK: Export button

    @ViewBuilder
    private var exportButton: some View {
        if let url = vm.exportURL {
            ShareLink(item: url) {
                HStack {
                    Text("Export my reflections")
                        .font(AppTheme.Fonts.labelSans)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        } else {
            Button {
                Task { await vm.exportCSV(entries: entries) }
            } label: {
                HStack {
                    if vm.isExporting {
                        ProgressView()
                            .tint(AppTheme.Colors.textSecondary)
                    } else {
                        Text("Export my reflections")
                            .font(AppTheme.Fonts.labelSans)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .disabled(vm.isExporting)
            .buttonStyle(.plain)
        }
    }

    // MARK: Import button

    private var importButton: some View {
        Button {
            vm.showImportFilePicker = true
        } label: {
            HStack {
                if vm.isImporting {
                    ProgressView()
                        .tint(AppTheme.Colors.textSecondary)
                } else {
                    Text("Import from CSV")
                        .font(AppTheme.Fonts.labelSans)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Spacer()
                Image(systemName: "arrow.down.doc")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .disabled(vm.isImporting)
        .buttonStyle(.plain)
    }

    // MARK: Section wrapper

    @ViewBuilder
    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTheme.Fonts.captionSans)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.8)
            content()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: DailyEntry.self, inMemory: true)
            .environment(AppViewModel())
    }
}
