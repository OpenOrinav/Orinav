import SwiftUI
import CoreLocation

struct BeaconUIUtils {
    static func formattedDistance(_ meters: CLLocationDistance) -> String {
        if meters >= 1000 {
            let kmValue = meters / 1000.0
            let unit = NSLocalizedString("km", comment: "Kilometer unit")
            return String(format: "%.1f %@", kmValue, unit)
        } else {
            let unit = NSLocalizedString("m", comment: "Meter unit")
            return String(format: "%lld %@", Int(meters), unit)
        }
    }
    
    static func formattedArrivalTime(_ secondsRemaining: Int) -> String {
        let arrivalDate = Date().addingTimeInterval(TimeInterval(secondsRemaining))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: arrivalDate)
    }
    
    static func formattedTimeRemaining(_ secondsRemaining: Int) -> String {
        let hours = secondsRemaining / 3600
        let minutes = (secondsRemaining % 3600) / 60
        let hrUnit = NSLocalizedString("hr", comment: "Hour unit abbreviation")
        let minUnit = NSLocalizedString("min", comment: "Minute unit abbreviation")
        
        if hours > 0 {
            return String(format: "%d %@ %d %@", hours, hrUnit, minutes, minUnit)
        } else {
            return String(format: "%d %@", minutes, minUnit)
        }
    }
}
