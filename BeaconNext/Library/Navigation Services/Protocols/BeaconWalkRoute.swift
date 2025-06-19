protocol BeaconWalkRoute: Equatable {
    var bid: String { get }
    var bOrigin: any BeaconPOI { get }
    var bDestination: any BeaconPOI { get }
    var bDistanceMeters: Int { get }
    var bTimeMinutes: Int { get }
}

extension BeaconWalkRoute {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.bid == rhs.bid
    }
}
