import SwiftUI
import SwiftData

struct DailyEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyEntry.date, order: .reverse) private var entries: [DailyEntry]

    @State private var vm = DailyEntryViewModel()

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Layout.sectionSpacing) {

                // Date header
                Text(dateLabel)
                    .font(AppTheme.Fonts.captionSans)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .kerning(0.8)
                    .padding(.top, 24)

                Text("How was today?")
                    .font(AppTheme.Fonts.headingSerif)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                // Mood
                MoodSliderView(value: $vm.moodScore)
                    .padding(.vertical, 4)

                Divider().background(AppTheme.Colors.divider)

                // Energy
                EnergySliderView(value: $vm.energyLevel)
                    .padding(.vertical, 4)

                Divider().background(AppTheme.Colors.divider)

                // One word
                VStack(alignment: .leading, spacing: 10) {
                    Text("One word for today")
                        .font(AppTheme.Fonts.captionSans)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .kerning(0.8)

                    TextField("focused", text: $vm.oneWord)
                        .font(AppTheme.Fonts.bodySerif)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Divider().background(AppTheme.Colors.divider)

                // What mattered
                VStack(alignment: .leading, spacing: 10) {
                    Text("What mattered today?")
                        .font(AppTheme.Fonts.captionSans)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .kerning(0.8)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $vm.whatMattered)
                            .font(AppTheme.Fonts.bodySerif)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(AppTheme.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                            .frame(minHeight: 120)

                        if vm.whatMattered.isEmpty {
                            Text("Today I spent time thinking about...")
                                .font(AppTheme.Fonts.bodySerif)
                                .foregroundStyle(AppTheme.Colors.textSecondary.opacity(0.5))
                                .padding(.leading, 8)
                                .padding(.top, 10)
                                .allowsHitTesting(false)
                        }
                    }
                }

                Divider().background(AppTheme.Colors.divider)

                // Voice note
                VoiceNoteView(service: vm.voiceNoteService)

                // Save button
                Button {
                    Task { await saveAndDismiss() }
                } label: {
                    HStack {
                        if vm.isSaving {
                            ProgressView()
                                .tint(AppTheme.Colors.textPrimary)
                        } else {
                            Text(vm.isEditMode ? "Update Entry" : "Save Entry")
                                .font(AppTheme.Fonts.buttonSans)
                                .foregroundStyle(
                                    vm.isSaveEnabled
                                        ? AppTheme.Colors.textPrimary
                                        : AppTheme.Colors.textSecondary
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
                }
                .disabled(!vm.isSaveEnabled || vm.isSaving)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, AppTheme.Layout.horizontalPadding)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground()
        .onAppear {
            vm.loadTodayEntry(from: entries)
        }
    }

    private func saveAndDismiss() async {
        await vm.saveEntry(context: modelContext)
        if vm.didSave { dismiss() }
    }
}

#Preview {
    NavigationStack {
        DailyEntryView()
            .modelContainer(for: DailyEntry.self, inMemory: true)
            .environment(AppViewModel())
    }
}
