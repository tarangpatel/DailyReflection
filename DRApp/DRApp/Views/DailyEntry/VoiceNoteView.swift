import SwiftUI
import AVFoundation

// MARK: - VoiceNoteView

/// WhatsApp-style voice note widget.
/// • Hold the mic button to record → release to save.
/// • Swipe the playback bar left to delete the recording.
struct VoiceNoteView: View {

    let service: VoiceNoteService

    /// Tracks whether the mic button is physically held down.
    @GestureState private var isHoldingMic = false
    /// Horizontal drag offset for the swipe-to-delete animation.
    @State private var swipeOffset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voice note")
                .font(AppTheme.Fonts.captionSans)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .kerning(0.8)

            switch service.state {
            case .idle:
                idleButton
            case .recording:
                recordingRow
            case .recorded, .playing:
                playbackRow
            case .permissionDenied:
                permissionDeniedRow
            }

            if service.state == .recorded || service.state == .playing {
                transcriptView
            }
        }
    }

    // MARK: - Transcript

    private var transcriptView: some View {
        Group {
            if service.isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Transcribing…")
                        .font(AppTheme.Fonts.captionSans)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            } else if !service.transcript.isEmpty {
                Text(service.transcript)
                    .font(AppTheme.Fonts.bodySerif)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Permission denied

    private var permissionDeniedRow: some View {
        HStack(spacing: 14) {
            micCircle(isActive: false)

            VStack(alignment: .leading, spacing: 2) {
                Text("Microphone access is off")
                    .font(AppTheme.Fonts.labelSans)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(AppTheme.Fonts.captionSans)
                .foregroundStyle(AppTheme.Colors.accent)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Idle: hold-to-record button

    private var idleButton: some View {
        HStack(spacing: 14) {
            micCircle(isActive: false)
                // Press-and-hold gesture — works reliably inside ScrollView
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isHoldingMic) { _, state, _ in state = true }
                        .onEnded { _ in service.stopRecording() }
                )
                .onChange(of: isHoldingMic) { _, holding in
                    if holding {
                        Task { await service.requestPermissionAndStart() }
                    }
                }

            Text("Hold to record")
                .font(AppTheme.Fonts.labelSans)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Record voice note")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            Task { await service.requestPermissionAndStart() }
        }
    }

    // MARK: - Recording row

    private var recordingRow: some View {
        HStack(spacing: 14) {
            // Pulsing red dot (release gesture lives here too)
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 45, height: 45)
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                    .opacity(isHoldingMic ? 1.0 : 0.0)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isHoldingMic) { _, state, _ in state = true }
                    .onEnded { _ in service.stopRecording() }
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    RecordingWaveformView()
                    Text(service.formattedDuration)
                        .font(AppTheme.Fonts.captionSans.monospacedDigit())
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Text("Release to save")
                    .font(AppTheme.Fonts.captionSans)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recording, \(service.formattedDuration)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            service.stopRecording()
        }
    }

    // MARK: - Playback row (swipe-to-delete)

    private var playbackRow: some View {
        ZStack {
            // Red delete background revealed on swipe
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                    Text("Delete")
                        .font(AppTheme.Fonts.captionSans)
                        .foregroundStyle(.white)
                }
                .padding(.trailing, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
            .accessibilityHidden(true)

            // Playback content — slides over the red background
            HStack(spacing: 12) {
                // Play / pause button
                Button {
                    if service.state == .playing {
                        service.stopPlayback()
                    } else {
                        service.play()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.textSecondary.opacity(0.14))
                            .frame(width: 38, height: 38)
                        Image(systemName: service.state == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .offset(x: service.state == .playing ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(service.state == .playing ? "Pause" : "Play")

                // Progress track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.Colors.textSecondary.opacity(0.18))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.Colors.textPrimary.opacity(0.55))
                            .frame(
                                width: max(0, geo.size.width * service.playbackProgress),
                                height: 4
                            )
                            .animation(.linear(duration: 0.05), value: service.playbackProgress)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 4)

                // Duration
                Text(service.formattedDuration)
                    .font(AppTheme.Fonts.captionSans.monospacedDigit())
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(minWidth: 36, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color("BackgroundTop"))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius))
            .offset(x: swipeOffset)
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        if value.translation.width < 0 {
                            // Rubber-band feel: resist after –60 pt
                            let raw = value.translation.width
                            swipeOffset = raw > -60 ? raw : -60 + (raw + 60) * 0.25
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -60 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                // Off-screen in either direction; exact distance doesn't matter.
                                swipeOffset = -1000
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                                service.deleteRecording()
                                swipeOffset = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                swipeOffset = 0
                            }
                        }
                    }
            )
            .accessibilityAction(named: "Delete") {
                service.deleteRecording()
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private func micCircle(isActive: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.red.opacity(0.12) : AppTheme.Colors.surface)
                .frame(width: 52, height: 52)
            Image(systemName: "mic.fill")
                .font(.system(size: 20))
                .foregroundStyle(isActive ? Color.red : AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Animated Waveform

private struct RecordingWaveformView: View {

    @State private var heights: [CGFloat] = [0.4, 0.7, 0.5, 0.9, 0.4, 0.6, 0.3]
    @State private var timer: Timer?

    private let columns = 7
    private let barWidth: CGFloat = 3
    private let maxBarHeight: CGFloat = 20

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0 ..< columns, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red.opacity(0.75))
                    .frame(width: barWidth, height: maxBarHeight * heights[i])
                    .animation(
                        .easeInOut(duration: 0.12).delay(Double(i) * 0.02),
                        value: heights[i]
                    )
            }
        }
        .frame(height: maxBarHeight)
        .onAppear { startAnimating() }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startAnimating() {
        // Re-randomise bar heights every 130 ms to simulate a live waveform.
        timer = Timer.scheduledTimer(withTimeInterval: 0.13, repeats: true) { _ in
            heights = (0 ..< columns).map { _ in CGFloat.random(in: 0.15 ... 1.0) }
        }
    }
}

#Preview {
    
    VStack(spacing: 24) {
        VoiceNoteView(service: VoiceNoteService(state: .recorded))
    }
    .padding()
    .appBackground()
}
