import AVFoundation
import UIKit

class SoundEffectsManager {
    static let shared = SoundEffectsManager()
    
    private var successSound: AVAudioPlayer?
    private var success2Sound: AVAudioPlayer?
    private var exploreSound: AVAudioPlayer?
    private var tapLowSound: AVAudioPlayer?
    private var tapMidSound: AVAudioPlayer?
    private var tapHighSound: AVAudioPlayer?
    private var redSound: AVAudioPlayer?
    private var greenSound: AVAudioPlayer?

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
        
        if let tapLowUrl = Bundle.main.url(forResource: "tap-low", withExtension: "mp3") {
            tapLowSound = try? AVAudioPlayer(contentsOf: tapLowUrl)
            tapLowSound?.prepareToPlay()
        }
        
        if let tapMidUrl = Bundle.main.url(forResource: "tap-mid", withExtension: "mp3") {
            tapMidSound = try? AVAudioPlayer(contentsOf: tapMidUrl)
            tapMidSound?.prepareToPlay()
        }
        
        if let tapHighUrl = Bundle.main.url(forResource: "tap-high", withExtension: "mp3") {
            tapHighSound = try? AVAudioPlayer(contentsOf: tapHighUrl)
            tapHighSound?.prepareToPlay()
        }
        
        if let redUrl = Bundle.main.url(forResource: "red", withExtension: "wav") {
            redSound = try? AVAudioPlayer(contentsOf: redUrl)
            redSound?.prepareToPlay()
        }
        
        if let greenUrl = Bundle.main.url(forResource: "green", withExtension: "wav") {
            greenSound = try? AVAudioPlayer(contentsOf: greenUrl)
            greenSound?.prepareToPlay()
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
    
    func playTapLow() {
        tapLowSound?.play()
    }
    
    func playTapMid() {
        tapMidSound?.play()
    }
    
    func playTapHigh() {
        tapHighSound?.play()
    }
    
    func playGreen() {
        greenSound?.play()
        DispatchQueue.main.async {
            self.heavyGen.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.59) {
            self.heavyGen.impactOccurred()
        }
    }
    
    func playRed() {
        redSound?.play()
        DispatchQueue.main.async {
            self.heavyGen.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.59) {
            self.heavyGen.impactOccurred()
        }
    }
}
