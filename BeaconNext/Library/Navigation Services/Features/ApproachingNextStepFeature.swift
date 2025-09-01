final class ApproachingNextStepFeature {
    static let shared = ApproachingNextStepFeature()
    
    private init() {}
    
    var lastSpokenDistance: Int = -100
    
    func reset() {
        lastSpokenDistance = -100
    }
    
    func notify(_ data: BeaconNavigationStatus) {
        if lastSpokenDistance == data.bDistanceToNextSegmentMeters {
            return
        }
        lastSpokenDistance = data.bDistanceToNextSegmentMeters
        
        let turnName = String(localized: data.bTurnType.localizedName)
        if data.bDistanceToNextSegmentMeters <= 2 {
            Task { @MainActor in
                BeaconTTSService.shared.speak(String(localized: "Now, \(turnName)"), type: .navigationImportant)
            }
        } else if data.bDistanceToNextSegmentMeters <= 20 && data.bDistanceToNextSegmentMeters % 5 == 0 {
            Task { @MainActor in
                BeaconTTSService.shared.speak(String(localized: "In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters))), \(turnName)"), type: .navigation)
            }
        } else if data.bDistanceToNextSegmentMeters % 10 == 0 {
            Task { @MainActor in
                BeaconTTSService.shared.speak(String(localized: "In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters))), \(turnName)"), type: .navigationAuxilary)
            }
        }
    }
}
