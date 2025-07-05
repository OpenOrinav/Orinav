import AVFoundation
import UIKit

class SoundEffectsManager {
    static let shared = SoundEffectsManager()
    
    private var successSound: AVAudioPlayer?

    private let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    
    private init() {
        if let url = Bundle.main.url(forResource: "success", withExtension: "mp3") {
            successSound = try? AVAudioPlayer(contentsOf: url)
            successSound?.prepareToPlay()
        }
        
        heavyGen.prepare()
    }
    
    func playSuccess() {
        successSound?.play()
        
        // Timing-matched haptics to make the user feel nice
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.heavyGen.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.heavyGen.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.27) {
            self.heavyGen.impactOccurred()
        }
    }
}
