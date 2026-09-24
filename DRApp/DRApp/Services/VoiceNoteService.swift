import Foundation
import AVFoundation
import Speech
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
    /// Speech-to-text transcript of the recorded note, in the app's language (English fallback).
    var transcript: String = ""
    /// Whether a transcription pass is currently running.
    var isTranscribing: Bool = false

    // MARK: Private

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var tempURL: URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("drapp_voice_note_temp.m4a")
    }
    
    init(state: RecordingState = .idle,
         recordingDuration: TimeInterval = 0,
         playbackProgress: Double = 0,
         audioData: Data? = nil,
         transcript: String = "",
         isTranscribing: Bool = false,
         audioRecorder: AVAudioRecorder? = nil,
         audioPlayer: AVAudioPlayer? = nil,
         recordingTimer: Timer? = nil,
         playbackTimer: Timer? = nil) {

        self.state = state
        self.recordingDuration = recordingDuration
        self.playbackProgress = playbackProgress
        self.audioData = audioData
        self.transcript = transcript
        self.isTranscribing = isTranscribing
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
        self.recordingTimer = recordingTimer
        self.playbackTimer = playbackTimer
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

            recognitionTask?.cancel()
            recognitionTask = nil
            transcript = ""

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
            transcribe(data)
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
        recognitionTask?.cancel()
        recognitionTask = nil
        audioData = nil
        transcript = ""
        isTranscribing = false
        recordingDuration = 0
        state = .idle
    }

    // MARK: - Load saved data

    /// - Parameter transcript: A previously-saved transcript, if any. When provided, it's used
    ///   as-is instead of re-running speech recognition on the audio.
    func loadAudioData(_ data: Data, transcript: String? = nil) {
        audioData = data
        if let p = try? AVAudioPlayer(data: data) {
            recordingDuration = p.duration
        }
        state = .recorded
        if let transcript, !transcript.isEmpty {
            self.transcript = transcript
        } else {
            transcribe(data)
        }
    }

    // MARK: - Transcription

    /// Transcribes the recorded audio in the app's current language, falling back to English
    /// when that language isn't supported by on-device speech recognition.
    private func transcribe(_ data: Data) {
        recognitionTask?.cancel()
        recognitionTask = nil
        transcript = ""

        Task { [weak self] in
            guard let self else { return }
            let authorized = await self.requestSpeechRecognitionPermission()
            guard authorized else { return }

            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, conformingTo: .mpeg4Audio)
            do {
                try data.write(to: fileURL)
            } catch {
                logger.error("transcribe write failed: \(error.localizedDescription)")
                return
            }
            defer { try? FileManager.default.removeItem(at: fileURL) }

            guard let recognizer = SFSpeechRecognizer(locale: Self.transcriptionLocale()),
                  recognizer.isAvailable else { return }

            self.isTranscribing = true
            defer { self.isTranscribing = false }

            let request = SFSpeechURLRecognitionRequest(url: fileURL)
            request.shouldReportPartialResults = false

            do {
                self.transcript = try await self.recognize(recognizer: recognizer, request: request)
            } catch {
                logger.error("transcribe failed: \(error.localizedDescription)")
            }
        }
    }

    private func recognize(recognizer: SFSpeechRecognizer, request: SFSpeechURLRecognitionRequest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var didResume = false
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    guard !didResume else { return }
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }
                if let result, result.isFinal {
                    guard !didResume else { return }
                    didResume = true
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    private func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    /// The app's current language (matching the device's language settings), falling back to
    /// English when speech recognition doesn't support it.
    private static func transcriptionLocale() -> Locale {
        let preferredLanguageCode = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
            .language.languageCode?.identifier
        if let preferredLanguageCode,
           let match = SFSpeechRecognizer.supportedLocales().first(where: { $0.language.languageCode?.identifier == preferredLanguageCode }) {
            return match
        }
        return Locale(identifier: "en-US")
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
