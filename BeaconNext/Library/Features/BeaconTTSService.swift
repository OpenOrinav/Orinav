import AVFoundation
import Foundation

enum MessageType: Int {
    case currentHeading = 1
    case currentLocation = 2
    case navigationAuxilary = 3
    case angleDeviation = 4
    case navigation = 5
    case navigationImportant = 6
}

@MainActor
final class BeaconTTSService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = BeaconTTSService()
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var currentPriority: MessageType = .currentHeading

    override private init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func speak(_ text: String, type: MessageType, language: String = "en-US") {
        guard type.rawValue >= currentPriority.rawValue else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentPriority = type
        
        // Play a sound for navigationImportant
        if type == .navigationImportant {
            SoundEffectsManager.shared.playSuccess2()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let utterance = AVSpeechUtterance(string: text)
                utterance.voice = AVSpeechSynthesisVoice(language: language)
                utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                self.synthesizer.speak(utterance)
            }
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    public func speak(_ segments: [(text: String, language: String)], type: MessageType) {
        guard type.rawValue >= currentPriority.rawValue else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        currentPriority = type

        // Play a sound for navigationImportant
        if type == .navigationImportant {
            SoundEffectsManager.shared.playSuccess2()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                for segment in segments {
                    let utterance = AVSpeechUtterance(string: segment.text)
                    utterance.voice = AVSpeechSynthesisVoice(language: segment.language)
                    utterance.rate = AVSpeechUtteranceDefaultSpeechRate
                    self.synthesizer.speak(utterance)
                }
            }
            return
        }
        
        for segment in segments {
            let utterance = AVSpeechUtterance(string: segment.text)
            utterance.voice = AVSpeechSynthesisVoice(language: segment.language)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utterance)
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.currentPriority = .currentHeading
        }
    }
}
