import SwiftUI
import CoreLocation

protocol BeaconPOI: Equatable {
    var bid: String { get }
    var bName: String { get }
    var bAddress: String { get }
    var bCategory: BeaconPOICategory { get }
    var bCoordinate: CLLocationCoordinate2D { get }

    var bIcon: String { get }
    var bIconColor: Color { get }
}

extension BeaconPOI {
    var bIcon: String {
        switch bCategory {
        case .foodAndDrink:
            return "fork.knife.circle.fill"
        case .shopping:
            return "cart.circle.fill"
        case .healthServices:
            return "cross.case.circle.fill"
        case .office:
            return "building.2.crop.circle.fill"
        case .education:
            return "graduationcap.circle.fill"
        case .lodging:
            return "bed.double.circle.fill"
        case .transportation:
            return "car.2.circle.fill"
        case .grocery:
            return "cart.circle.fill"
        case .outdoors:
            return "leaf.circle.fill"
        case .entertainment:
            return "ticket.circle.fill"
        case .financialServices:
            return "dollarsign.circle.fill"
        case .sportsAndFitness:
            return "sportscourt.circle.fill"
        case .government:
            return "person.2.crop.square.fill"
        case .placeOfWorship:
            return "person.3.sequence.fill"
        case .residential:
            return "house.circle.fill"
        case .services:
            return "wrench.and.screwdriver.circle.fill"
        case .cultural:
            return "building.columns.circle.fill"
        case .others:
            return "mappin.circle.fill"
        }
    }
    
    var bIconColor: Color {
        switch bCategory {
        case .foodAndDrink:
            return .orange
        case .shopping:
            return .blue
        case .healthServices:
            return .red
        case .office:
            return .gray
        case .education:
            return .blue
        case .lodging:
            return .purple
        case .transportation:
            return .teal
        case .grocery:
            return .green
        case .outdoors:
            return .green
        case .entertainment:
            return .pink
        case .financialServices:
            return .green
        case .sportsAndFitness:
            return .blue
        case .government:
            return .blue
        case .placeOfWorship:
            return .yellow
        case .residential:
            return .brown
        case .services:
            return .gray
        case .cultural:
            return .purple
        case .others:
            return .secondary
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.bid == rhs.bid
    }
}

public enum BeaconPOICategory: String, CaseIterable {
    case foodAndDrink      = "Food & Drink"
    case shopping          = "Shopping"
    case healthServices    = "Health Services"
    case office            = "Office"
    case education         = "Education"
    case lodging           = "Lodging"
    case transportation    = "Transportation"
    case grocery           = "Grocery"
    case outdoors          = "Outdoors"
    case entertainment     = "Entertainment"
    case financialServices = "Financial Services"
    case sportsAndFitness  = "Sports & Fitness"
    case government        = "Government"
    case placeOfWorship    = "Place of Worship"
    case residential       = "Residential"
    case services          = "Services"
    case cultural          = "Cultural"
    case others            = "Others"
}
