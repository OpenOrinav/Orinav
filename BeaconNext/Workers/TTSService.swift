import AVFoundation

final class TTSService {
    static let shared = TTSService()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(_ text: String, language: String = "en-US") {
        guard !synthesizer.isSpeaking else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func speak(_ segments: [(text: String, language: String)]) {
        guard !synthesizer.isSpeaking else { return }
        for segment in segments {
            let utterance = AVSpeechUtterance(string: segment.text)
            utterance.voice = AVSpeechSynthesisVoice(language: segment.language)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(utterance)
        }
    }
}
