final class ApproachingNextStepFeature {
    static let shared = ApproachingNextStepFeature()
    
    private init() {}
    
    var lastSpokenDistance: Int = -100
    private var hasSpokenNowForThisStep = false
    private var lastTenMeterSpokenDistance: Int = -1
    
    func reset() {
        lastSpokenDistance = -100
        hasSpokenNowForThisStep = false
        lastTenMeterSpokenDistance = -1
    }
    
    func notify(_ data: BeaconNavigationStatus) {
        if lastSpokenDistance == data.bDistanceToNextSegmentMeters {
            return
        }
        lastSpokenDistance = data.bDistanceToNextSegmentMeters
        
        if lastTenMeterSpokenDistance == -1 {
            lastTenMeterSpokenDistance = data.bDistanceToNextSegmentMeters
        } else if data.bDistanceToNextSegmentMeters >= lastTenMeterSpokenDistance {
            lastTenMeterSpokenDistance = data.bDistanceToNextSegmentMeters
        }
        
        if data.bDistanceToNextSegmentMeters > 5 {
            hasSpokenNowForThisStep = false
        }
        
        let turnName = String(localized: data.bTurnType.localizedName)
        if data.bDistanceToNextSegmentMeters <= 5 {
            // Only speak "Now" once
            if !hasSpokenNowForThisStep {
                hasSpokenNowForThisStep = true
                Task { @MainActor in
                    BeaconTTSService.shared.speak(String(localized: "Now, \(turnName)"), type: .navigationImportant)
                }
            }
        } else if (lastTenMeterSpokenDistance - data.bDistanceToNextSegmentMeters) >= 10 {
            lastTenMeterSpokenDistance = data.bDistanceToNextSegmentMeters
            Task { @MainActor in
                BeaconTTSService.shared.speak(String(localized: "In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters))), \(turnName)"), type: .navigationAuxilary)
            }
        }
    }
}
