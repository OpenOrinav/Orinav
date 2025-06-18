protocol BeaconWalkRoute {
    var bid: String { get }
    var bOrigin: BeaconPOI { get }
    var bDestination: BeaconPOI { get }
    var bDistanceMeters: Int { get }
    var bTimeMinutes: Int { get }
}
