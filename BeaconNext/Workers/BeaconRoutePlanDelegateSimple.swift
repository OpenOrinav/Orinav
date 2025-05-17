import AMapNaviKit
import AMapSearchKit

class BeaconRoutePlanDelegateSimple: NSObject, ObservableObject, AMapNaviWalkManagerDelegate {
    let walkManager: AMapNaviWalkManager
    @Published var lastRoutes: [AMapNaviRoute] = []
    
    override init() {
        self.walkManager = AMapNaviWalkManager.sharedInstance()
        super.init()
        self.walkManager.delegate = self
    }
    
    func planRoutes(from: AMapPOI?, to: AMapPOI) {
        lastRoutes.removeAll()
        let startPOIInfo = AMapNaviPOIInfo()
        if let from = from {
            startPOIInfo.mid = from.uid
        }
        let endPOIInfo = AMapNaviPOIInfo()
        endPOIInfo.mid = to.uid
        print("Tried to calculate route")
        walkManager.calculateWalkRoute(withStart: from == nil ? nil : startPOIInfo, end: endPOIInfo, strategy: .multipleDefault)
    }
    
    func walkManager(onCalculateRouteSuccess: AMapNaviWalkManager) {
        // FIXME Somehow this callback isn't fired and I cannot for the life of me figure out what's wrong
        print("Success")
        lastRoutes = onCalculateRouteSuccess.naviRoutes().map { $0.value }
    }
}
