import QMapKit
import TencentNavKit
import CoreLocation
import CoreMotion
import Foundation

class BeaconLocationDelegateSimple: NSObject, ObservableObject, TencentLBSLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    @Published var lastAddress: String?

    private var locationManager: TencentLBSLocationManager
    private let motionManager = CMMotionManager()
    private var lastShakeTime: Date? = nil
    private var lastAccel: CMAcceleration?

    init(_ apiKey: String) {
        self.locationManager = TencentLBSLocationManager()
        self.locationManager.apiKey = apiKey
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.requestLevel = .name

        let cl = CLLocationManager()
        if cl.authorizationStatus == .notDetermined {
            self.locationManager.requestWhenInUseAuthorization()
        }

        super.init()
        self.locationManager.delegate = self
        self.locationManager.headingFilter = 10
        self.locationManager.startUpdatingHeading()
        self.locationManager.startUpdatingLocation()

        startShakeDetection()
    }

    func tencentLBSLocationManager(
        _ manager: TencentLBSLocationManager,
        didUpdate location: TencentLBSLocation
    ) {
        DispatchQueue.main.async {
            self.lastLocation = location.location
            self.lastAddress = location.name
            self.speakAddress()

            let degrees = location.direction
            let directions = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest"]
            let index = Int((degrees + 22.5) / 45) & 7
            let dir = directions[index]

            self.speakFacingDirection(direction: dir)
        }
    }

    // MARK: - Speaking
    private var lastSpokenAddress: String?
    private var lastSpokenDirection: String?
    private var isFirstWord = true

    func speakAddress(force: Bool = false) {
        guard let currentAddress = lastAddress else { return }

        if force || currentAddress != lastSpokenAddress {
            BeaconTTSService.shared.speak([
                (text: "You are currently at", language: "en-US"),
                (text: currentAddress, language: "zh-CN")
            ])
            lastSpokenAddress = currentAddress
            isFirstWord = false
        }
    }

    func speakFacingDirection(direction: String) {
        if direction == lastSpokenDirection || isFirstWord {
            return
        }
        BeaconTTSService.shared.speak([
            (text: direction, language: "en-US")
        ])
        lastSpokenDirection = direction
    }

    // MARK: - Shake Detection
    private func startShakeDetection() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, error in
            guard let data = data else { return }

            let accel = data.acceleration

            if let last = self.lastAccel {
                let deltaX = abs(accel.x - last.x)
                let deltaY = abs(accel.y - last.y)
                let deltaZ = abs(accel.z - last.z)

                let shakeThreshold = 1.0 // Sensitivity
                let cooldown: TimeInterval = 3.0

                if deltaX > shakeThreshold || deltaY > shakeThreshold || deltaZ > shakeThreshold {
                    let now = Date()
                    if let last = self.lastShakeTime, now.timeIntervalSince(last) < cooldown {
                        return
                    }

                    self.lastShakeTime = now
                    print("Shake detected. Speaking address...")
                    self.speakAddress(force: true)
                }
            }

            self.lastAccel = accel
        }
    }
}
