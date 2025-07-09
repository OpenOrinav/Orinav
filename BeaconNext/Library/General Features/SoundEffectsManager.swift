import AVFoundation
import UIKit

class SoundEffectsManager {
    static let shared = SoundEffectsManager()
    
    private var successSound: AVAudioPlayer?
    private var success2Sound: AVAudioPlayer?
    private var exploreSound: AVAudioPlayer?

    private let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    
    private init() {
        if let url = Bundle.main.url(forResource: "success", withExtension: "mp3") {
            successSound = try? AVAudioPlayer(contentsOf: url)
            successSound?.prepareToPlay()
        }
        
        if let url2 = Bundle.main.url(forResource: "success-2", withExtension: "mp3") {
            success2Sound = try? AVAudioPlayer(contentsOf: url2)
            success2Sound?.prepareToPlay()
        }
        
        if let exploreUrl = Bundle.main.url(forResource: "explore", withExtension: "mp3") {
            exploreSound = try? AVAudioPlayer(contentsOf: exploreUrl)
            exploreSound?.prepareToPlay()
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
    
    func playSuccess2() {
        success2Sound?.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.heavyGen.impactOccurred()
        }
    }
    
    func playExplore() {
        exploreSound?.play()
    }
}
