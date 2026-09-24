import Foundation
import AVFoundation
import os

// MARK: - VoiceNoteService

private let logger = Logger(subsystem: "com.tarangp.DRApp", category: "VoiceNoteService")

/// Manages audio recording and playback for the optional daily voice note.
/// Press-and-hold to record; release to save. Swipe-to-delete handled in the view layer.
@Observable
final class VoiceNoteService: NSObject {

    // MARK: State

    enum RecordingState: Equatable {
        case idle
        case recording
        case recorded
        case playing
        case permissionDenied
    }

    var state: RecordingState = .idle
    /// Elapsed recording time in seconds (also used as total duration after recording).
    var recordingDuration: TimeInterval = 0
    /// 0.0 – 1.0 playback position used to animate the progress bar.
    var playbackProgress: Double = 0
    /// Raw M4A bytes of the recorded note (nil when nothing has been recorded).
    var audioData: Data?

    // MARK: Private

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?

    private var tempURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("drapp_voice_note_temp.m4a")
    }

    // MARK: - Permission + Start Recording

    func requestPermissionAndStart() async {
        let granted = await requestMicrophonePermission()
        guard granted else {
            state = .permissionDenied
            return
        }
        startRecording()
    }

    private func requestMicrophonePermission() async -> Bool {
#if os(iOS) || os(visionOS)
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { cont in
                AVAudioSession.sharedInstance().requestRecordPermission { ok in
                    cont.resume(returning: ok)
                }
            }
        }
#elseif os(macOS)
        return await withCheckedContinuation { cont in
            AVCaptureDevice.requestAccess(for: .audio) { ok in
                cont.resume(returning: ok)
            }
        }
#else
        return false
#endif
    }

    private func startRecording() {
        do {
#if os(iOS) || os(visionOS)
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
#endif
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            state = .recording
            recordingDuration = 0
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.recordingDuration += 0.05
            }
        } catch {
            logger.error("startRecording failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Recording

    func stopRecording() {
        guard state == .recording else { return }
        recordingTimer?.invalidate()
        recordingTimer = nil
        audioRecorder?.stop()
        audioRecorder = nil

        if let data = try? Data(contentsOf: tempURL) {
            audioData = data
            if let p = try? AVAudioPlayer(data: data) {
                recordingDuration = p.duration
            }
            state = .recorded
            try? FileManager.default.removeItem(at: tempURL)
        } else {
            state = .idle
        }

#if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }

    // MARK: - Playback

    func play() {
        guard let data = audioData else { return }
        do {
#if os(iOS) || os(visionOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
#endif
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            state = .playing
            playbackProgress = 0
            let dur = audioPlayer?.duration ?? 0
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self, let p = self.audioPlayer else { return }
                self.playbackProgress = dur > 0 ? p.currentTime / dur : 0
            }
        } catch {
            logger.error("play failed: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackTimer?.invalidate()
        playbackTimer = nil
        playbackProgress = 0
        state = .recorded
#if os(iOS) || os(visionOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
#endif
    }

    // MARK: - Delete

    func deleteRecording() {
        if state == .playing { stopPlayback() }
        audioData = nil
        recordingDuration = 0
        state = .idle
    }

    // MARK: - Load saved data

    func loadAudioData(_ data: Data) {
        audioData = data
        if let p = try? AVAudioPlayer(data: data) {
            recordingDuration = p.duration
        }
        state = .recorded
    }

    // MARK: - Helpers

    var formattedDuration: String {
        let secs = Int(recordingDuration)
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceNoteService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
}

// MARK: - AVAudioPlayerDelegate

extension VoiceNoteService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playbackTimer?.invalidate()
            self.playbackTimer = nil
            self.playbackProgress = 0
            self.state = .recorded
        }
    }
}
