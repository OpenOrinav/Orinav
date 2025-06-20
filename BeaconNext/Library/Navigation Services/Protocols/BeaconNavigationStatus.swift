protocol BeaconNavigationStatus {
    var bNextRoad: String { get }
    var bCurrentRoad: String { get }
    var bDistanceToNextSegmentMeters: Int { get }
    var bTotalDistanceRemainingMeters: Int { get }
    var bCurrentSpeed: Int { get } // km/s
    var bTurnType: BeaconTurnType { get }
}

public enum BeaconTurnType: String, CaseIterable, Codable {
    case left = "left"
    case right = "right"
    case slightLeft = "slightLeft"
    case slightRight = "slightRight"
    case uTurn = "uTurn"
    case stop = "stop"
    case straight = "straight"
}
