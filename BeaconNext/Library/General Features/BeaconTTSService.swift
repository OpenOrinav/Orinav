import AVFoundation
import Foundation

enum MessageType: Int {
    case currentHeading = 1
    case currentLocation = 2
    case navigationAuxilary = 3
    case angleDeviation = 4
    case navigation = 5
    case navigationImportant = 6
    case explore = 7
}

@MainActor
final class BeaconTTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = BeaconTTSService()
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var currentPriority: MessageType = .currentHeading
    private let audioSession = AVAudioSession.sharedInstance()
    
    override private init() {
        super.init()
        synthesizer.delegate = self
        
        // Restart session after interruption
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let info = note.userInfo,
                let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: raw)
            else { return }
            switch type {
            case .began:
                break
            case .ended:
                DispatchQueue.main.async {
                    self?.ensureSessionActive()
                }
                break
            @unknown default: break
            }
        }
    }
    
    private func ensureSessionActive() {
        do {
            if audioSession.category != .playback {
                try audioSession.setCategory(.playback, options: [.duckOthers, .mixWithOthers, .allowBluetoothHFP, .allowAirPlay])
            }
            if !audioSession.isOtherAudioPlaying { /* optional heuristic */ }
            try audioSession.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    public func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }
    }
    
    public func interruptSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    public func speak(_ text: String, type: MessageType, language: String? = nil) {
        guard type.rawValue >= currentPriority.rawValue else { return }
        interruptSpeaking()
        currentPriority = type
        
        ensureSessionActive()
        
        // Play a sound for navigationImportant
        if type == .navigationImportant {
            SoundEffectsManager.shared.playSuccess2()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: language)
                utterance.rate = Float(SettingsManager.shared.speechRate)
                self.synthesizer.speak(utterance)
            }
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = Float(SettingsManager.shared.speechRate)
        synthesizer.speak(utterance)
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.currentPriority = .currentHeading
        }
    }
}
