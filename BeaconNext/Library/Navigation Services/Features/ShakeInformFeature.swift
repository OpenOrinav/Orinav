final class ShakeInformFeature {
    static let shared = ShakeInformFeature()
    
    private init() {}
    
    func speak(_ data: BeaconNavigationStatus, angleDiff: Double) {
        let message: String
        if data.bTurnType == .stop || data.bNextRoad == nil {
            message = "Arrive at your destination"
        } else {
            message = "\(data.bTurnType.localizedName) onto \(data.bNextRoad!)"
        }
        
        if abs(angleDiff) > AngleDeviationFeature.correctHeadingLimit {
            Task { @MainActor in
                BeaconTTSService.shared.speak([
                    (text: "Turn \(AngleDeviationFeature.oClockRepresentation(from: angleDiff)) o'clock to align with", language: "en-US"),
                    (text: data.bCurrentRoad, language: "zh-CN")
                ], type: .navigationImportant)
            }
        } else if data.bTotalDistanceRemainingMeters < 100 {
            Task { @MainActor in
                BeaconTTSService.shared.speak("Almost there. In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters))), \(message)", type: .navigationImportant)
            }
        } else {
            Task { @MainActor in
                BeaconTTSService.shared.speak("In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters))), \(message)", type: .navigationImportant)
            }
        }
    }
}
