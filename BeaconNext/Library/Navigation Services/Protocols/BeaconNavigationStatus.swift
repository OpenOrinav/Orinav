import SwiftUI

protocol BeaconNavigationStatus {
    var bNextRoad: String? { get }
    var bCurrentRoad: String { get }
    var bDistanceToNextSegmentMeters: Int { get }
    var bTotalDistanceRemainingMeters: Int { get }
    var bTimeRemainingSeconds: Int { get }
    var bTurnType: BeaconTurnType { get }
}

public enum BeaconTurnType: String, CaseIterable, Codable {
    case left = "left"
    case right = "right"
    case sharpLeft = "sharpLeft"
    case sharpRight = "sharpRight"
    case slightLeft = "slightLeft"
    case slightRight = "slightRight"
    case uTurn = "uTurn"
    case stop = "stop"
    case straight = "straight"
    case unnavigable = "unnavigable"
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .left: return "Turn left"
        case .right: return "Turn right"
        case .sharpLeft: return "Turn sharp left"
        case .sharpRight: return "Turn sharp right"
        case .slightLeft: return "Turn slightly left"
        case .slightRight: return "Turn slightly right"
        case .uTurn: return "Make a U-turn"
        case .stop: return "Stop"
        case .straight: return "Continue straight"
        case .unnavigable: return "Proceed to the nearest road"
        }
    }
}
