final class ShakeInformFeature {
    static let shared = ShakeInformFeature()
    
    private init() {}
    
    func speak(_ data: BeaconNavigationStatus, angleDiff: Double) {
        let message: String
        if data.bTurnType == .stop || data.bNextRoad == nil {
            message = String(localized: "Arrive at your destination")
        } else if data.bTurnType == .unnavigable {
            message = String(localized: data.bTurnType.localizedName)
        } else {
            message = String(localized: "\(String(localized: data.bTurnType.localizedName)) onto \(data.bNextRoad!)")
        }
        
        if abs(angleDiff) > AngleDeviationFeature.correctHeadingLimit {
            Task { @MainActor in
                BeaconTTSService.shared.speak(String(localized: "Turn \(AngleDeviationFeature.oClockRepresentation(from: angleDiff)) o'clock to align with \(data.bCurrentRoad)"), type: .navigationImportant)
            }
        } else if data.bTurnType == .unnavigable {
            Task { @MainActor in
                BeaconTTSService.shared.speak(String(localized: data.bTurnType.localizedName), type: .navigationImportant)
            }
        } else {
            Task { @MainActor in
                BeaconTTSService.shared
                    .speak(
                        data.bDistanceToNextSegmentMeters <= 5 ? String(localized: "Now, \(message)")
                        : String(localized: "In \(BeaconUIUtils.formattedDistance(Double(data.bDistanceToNextSegmentMeters))), \(message)"),
                        type: .navigationImportant
                    )
            }
        }
    }
}
