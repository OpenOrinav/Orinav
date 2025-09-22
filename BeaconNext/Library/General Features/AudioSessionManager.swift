import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()
    private init() {}
    private let session = AVAudioSession.sharedInstance()

    func configureAtLaunch() {
        do {
            try session.setCategory(.playback,
                                    mode: .spokenAudio,
                                    options: [.duckOthers, .allowBluetooth, .allowAirPlay, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession configure failed: \(error)")
        }

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
                do { try self?.session.setActive(true) } catch { }
            @unknown default: break
            }
        }
    }

    func ensureActive() {
        do { try session.setActive(true) } catch {
            print("AudioSession activate failed: \(error)")
        }
    }

    func politelyDeactivate() {
        do { try session.setActive(false, options: [.notifyOthersOnDeactivation]) } catch { }
    }
}
