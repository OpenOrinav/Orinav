import SwiftUI
import CoreLocation

final class UIUtils {
    static func iconName(for typeCode: String?) -> String {
        guard let code = typeCode else { return "mappin.circle.fill" }
        let prefix4 = String(code.prefix(4))
        switch prefix4 {
        case "1501": return "airplane.circle.fill"
        case "1502": return "tram.circle.fill"
        case "1503": return "ferry.circle.fill"
        case "1504": return "bus.circle.fill"
        case "1505", "1506": return "train.side.front.car.circle.fill"
        case "1507": return "bus.circle.fill"
        default:
            let prefix2 = String(code.prefix(2))
            switch prefix2 {
            case "01": return "car.circle.fill"
            case "02": return "car.circle.fill"
            case "03": return "wrench.circle.fill"
            case "04": return "motorcycle.circle.fill"
            case "05": return "fork.knife.circle.fill"
            case "06": return "bag.circle.fill"
            case "07": return "hammer.circle.fill"
            case "08": return "sportscourt.circle.fill"
            case "09": return "cross.case.circle.fill"
            case "10": return "bed.double.circle.fill"
            case "11": return "mappin.circle.fill"
            case "12": return "building.2.circle.fill"
            case "13": return "globe.circle.fill"
            case "14": return "book.circle.fill"
            case "15": return "tram.circle.fill"
            case "16": return "dollarsign.circle.fill"
            case "17": return "briefcase.circle.fill"
            case "18": return "lightbulb.circle.fill"
            case "19": return "mappin.circle.fill"
            case "20": return "person.3.circle.fill"
            default: return "mappin.circle.fill"
            }
        }
    }
    
    static func iconColor(for typeCode: String?) -> Color {
        guard let code = typeCode else { return .gray }
        let prefix4 = String(code.prefix(4))
        switch prefix4 {
        case "1501", "1502", "1503", "1504", "1505", "1506", "1507":
            return .blue
        default:
            let prefix2 = String(code.prefix(2))
            switch prefix2 {
            case "05": return .orange      // Restaurant
            case "09": return .red         // Medical services
            case "15": return .blue        // Transportation services
            case "16": return .green       // Financial services
            case "14": return .purple      // Education
            case "06": return .pink        // Shopping
            default: return .gray
            }
        }
    }
    
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
