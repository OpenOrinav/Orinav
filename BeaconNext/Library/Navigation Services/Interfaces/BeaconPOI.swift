import CoreLocation

protocol BeaconPOI {
    var bid: String { get }
    var bName: String { get }
    var bAddress: String { get }
    var bCategory: BeaconPOICategory { get }
    var bLocation: CLLocationCoordinate2D { get }
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
