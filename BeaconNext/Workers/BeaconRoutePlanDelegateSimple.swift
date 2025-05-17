import AMapNaviKit
import AMapSearchKit

class BeaconRoutePlanDelegateSimple: NSObject, ObservableObject, AMapNaviWalkManagerDelegate {
    var walkManager: AMapNaviWalkManager
    @Published var lastRoutes: [AMapNaviRoute] = []
    
    override init() {
        self.walkManager = AMapNaviWalkManager.sharedInstance()
        super.init()
        self.walkManager.delegate = self
    }
    
    func reinit() {
        AMapNaviWalkManager.destroyInstance()
        self.walkManager = AMapNaviWalkManager.sharedInstance()
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
        walkManager.calculateWalkRoute(withStart: from == nil ? nil : startPOIInfo, end: endPOIInfo, strategy: .multipleDefault)
    }
    
    func walkManager(onCalculateRouteSuccess manager: AMapNaviWalkManager) {
        lastRoutes = manager.naviRoutes().map { $0.value }
    }
}
