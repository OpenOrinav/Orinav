import SwiftUI
import CoreLocation

struct BeaconUIUtils {
    static func formattedDistance(_ distance: CLLocationDistance) -> String {
        switch distance {
        case 0..<10:
            let meters = Int(distance.rounded())
            return "\(meters)m"
        case 10..<100:
            let rounded10 = Int((distance / 10).rounded() * 10)
            return "\(rounded10)m"
        case 100..<1000:
            let rounded100 = Int((distance / 100).rounded() * 100)
            return "\(rounded100)m"
        default:
            let km = (distance / 1000.0 * 10).rounded() / 10
            return "\(km)km"
        }
    }
}
