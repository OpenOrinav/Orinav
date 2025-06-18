import SwiftUI

struct BeaconNavigationView: UIViewRepresentable {
    let navManager: BeaconNavigationProvider
    let selectedRoute: any BeaconWalkRoute
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(navManager.navView)
        navManager.startNavigation(with: selectedRoute)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
