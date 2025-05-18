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
    
    static func iconName(for categoryCode: String) -> String {
        let code = categoryCode
        switch code {
            // Food
        case _ where code.hasPrefix("10"):
            return "fork.knife.circle.fill"
            // Generic company
        case _ where code.hasPrefix("11"):
            return "building.2.crop.circle.fill"
            // Government
        case _ where code.hasPrefix("1214"):
            return "person.2.crop.square.fill"
            // Academic organization
        case _ where code.hasPrefix("1219"):
            return "graduationcap.circle.fill"
            // International organization
        case _ where code.hasPrefix("1211"):
            return "globe.circle.fill"
            // Court
        case _ where code.hasPrefix("1210"):
            return "gavel.circle.fill"
            // Generic organization (12 prefix, excluding above)
        case _ where code.hasPrefix("12"):
            return "person.3.sequence.fill"
            // Mall
        case _ where code.hasPrefix("13"):
            return "cart.circle.fill"
            // Post office
        case _ where code.hasPrefix("1412"):
            return "envelope.circle.fill"
            // ISP
        case _ where code.hasPrefix("1413"):
            return "antenna.radiowaves.left.and.right.circle.fill"
            // Other life services (14 prefix, excluding above)
        case _ where code.hasPrefix("14"):
            return "wrench.and.screwdriver.circle.fill"
            // Specific entertainment subcategories under 16
        case _ where code.hasPrefix("1616"):
            return "film.circle.fill"
        case _ where code.hasPrefix("1617"):
            return "theatermasks.circle.fill"
        case _ where code.hasPrefix("1612"):
            return "wineglass.circle.fill"
        case _ where code.hasPrefix("1613"):
            return "cup.and.saucer.circle.fill"
        case _ where code.hasPrefix("1619"):
            return "figure.walk.circle.fill"
        case _ where code.hasPrefix("1618"):
            return "sun.max.circle.fill"
        case _ where code.hasPrefix("1621"):
            return "desktopcomputer.circle.fill"
            // Other entertainment (16 prefix)
        case _ where code.hasPrefix("16"):
            return "ticket.circle.fill"
            // Sports
        case _ where code.hasPrefix("18"):
            return "sportscourt.circle.fill"
            // Gas station
        case _ where code.hasPrefix("1910"):
            return "fuelpump.circle.fill"
            // Parking lot
        case _ where code.hasPrefix("1911"):
            return "parkingsign.circle.fill"
            // Generic car services (19 prefix)
        case _ where code.hasPrefix("19"):
            return "car.circle.fill"
            // Medical services
        case _ where code.hasPrefix("20"):
            return "cross.case.circle.fill"
            // Hotels
        case _ where code.hasPrefix("21"):
            return "bed.double.circle.fill"
            // Park
        case _ where code.hasPrefix("2211"):
            return "leaf.circle.fill"
            // Botanical garden
        case _ where code.hasPrefix("2212"):
            return "leaf.arrow.circlepath.circle.fill"
            // Zoo
        case _ where code.hasPrefix("2213"):
            return "pawprint.circle.fill"
            // Generic tourist attractions (22 prefix)
        case _ where code.hasPrefix("22"):
            return "mappin.circle.fill"
            // Museums/exhibition (23 prefix)
        case _ where code.hasPrefix("23"):
            return "building.columns.circle.fill"
            // Schools
        case _ where code.hasPrefix("24"):
            return "book.circle.fill"
            // Financial services
        case _ where code.hasPrefix("25"):
            return "dollarsign.circle.fill"
            // Generic location (26 prefix)
        case _ where code.hasPrefix("26"):
            return "mappin.and.ellipse.circle.fill"
            // Transportation specifics under 27
        case _ where code.hasPrefix("271030"):
            return "tram.circle.fill"
        case _ where code.hasPrefix("271020"):
            return "airplane.circle.fill"
        case _ where code.hasPrefix("271021"):
            return "bus.circle.fill"
        case _ where code.hasPrefix("271018"):
            return "ferry.circle.fill"
        case _ where code.hasPrefix("271016"), _ where code.hasPrefix("271017"):
            return "train.side.front.car.circle.fill"
        case _ where code.hasPrefix("271015"):
            return "ship.circle.fill"
        case _ where code.hasPrefix("271014"), _ where code.hasPrefix("271013"):
            return "subway.circle.fill"
        case _ where code.hasPrefix("2713"):
            return "airplane.departure.circle.fill"
        case _ where code.hasPrefix("2714"):
            return "tram.fill.tunnel.circle.fill"
            // Generic transportation (27 prefix)
        case _ where code.hasPrefix("27"):
            return "car.2.circle.fill"
            // Residential quarters
        case _ where code.hasPrefix("28"):
            return "house.circle.fill"
            // Default: Others
        default:
            return "mappin.circle.fill"
        }
    }
    
    
    static func iconColor(for categoryCode: String) -> Color {
        let code = categoryCode
        switch code {
        case _ where code.hasPrefix("10"):
            return .orange
        case _ where code.hasPrefix("11"):
            return .gray
        case _ where code.hasPrefix("1214"):
            return .blue
        case _ where code.hasPrefix("1219"):
            return .purple
        case _ where code.hasPrefix("1211"):
            return .teal
        case _ where code.hasPrefix("1210"):
            return .red
        case _ where code.hasPrefix("12"):
            return .gray
        case _ where code.hasPrefix("13"):
            return .pink
        case _ where code.hasPrefix("1412"):
            return .brown
        case _ where code.hasPrefix("1413"):
            return .green
        case _ where code.hasPrefix("14"):
            return .brown
        case _ where code.hasPrefix("1616"),
            _ where code.hasPrefix("1617"),
            _ where code.hasPrefix("1612"),
            _ where code.hasPrefix("1613"),
            _ where code.hasPrefix("1619"),
            _ where code.hasPrefix("1618"),
            _ where code.hasPrefix("1621"),
            _ where code.hasPrefix("16"):
            return .purple
        case _ where code.hasPrefix("18"):
            return .green
        case _ where code.hasPrefix("1910"):
            return .orange
        case _ where code.hasPrefix("1911"):
            return .gray
        case _ where code.hasPrefix("19"):
            return .gray
        case _ where code.hasPrefix("20"):
            return .red
        case _ where code.hasPrefix("21"):
            return .blue
        case _ where code.hasPrefix("2211"),
            _ where code.hasPrefix("2212"),
            _ where code.hasPrefix("2213"):
            return .green
        case _ where code.hasPrefix("22"):
            return .cyan
        case _ where code.hasPrefix("23"):
            return .indigo
        case _ where code.hasPrefix("24"):
            return .blue
        case _ where code.hasPrefix("25"):
            return .green
        case _ where code.hasPrefix("26"):
            return .gray
        case _ where code.hasPrefix("271030"),
            _ where code.hasPrefix("271020"),
            _ where code.hasPrefix("271021"),
            _ where code.hasPrefix("271018"),
            _ where code.hasPrefix("271016"),
            _ where code.hasPrefix("271017"),
            _ where code.hasPrefix("271015"),
            _ where code.hasPrefix("271014"),
            _ where code.hasPrefix("271013"),
            _ where code.hasPrefix("2713"),
            _ where code.hasPrefix("2714"),
            _ where code.hasPrefix("27"):
            return .gray
        case _ where code.hasPrefix("28"):
            return .yellow
        default:
            return .gray
        }
    }
}
