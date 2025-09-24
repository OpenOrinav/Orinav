import Foundation
import UIKit

class BeaconGlobalUIState: ObservableObject {
    @Published var currentPage: BeaconPage? = nil // The sub-page within the home page
    
    // POI viewing page
    @Published var poi: (any BeaconPOI)?

    // Navigation page
    @Published var routeInNavigation: (any BeaconWalkRoute)?
    @Published var navigationStatus: (any BeaconNavigationStatus)? // Current navigation status, if any
    @Published var atIntersection: Bool? // Whether the user is at an intersection (during navigation only), if known

    // Routes page
    @Published var routesFrom: (any BeaconPOI)? // If nil, use current location; otherwise, use the selected POI
    @Published var routesDestination: (any BeaconPOI)? // If nil, use current location; otherwise, use the selected POI
    
    
    // Changelog data
    @Published var changelog: ChangelogData?
    
    init() {
        fetchChangelog()
        setupBackgroundNotification()
    }
    
    func fetchChangelog() {
        let url = URL(string: "https://distribution.orinav.com/changelog.json")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("Failed to fetch changelog: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(ChangelogData.self, from: data)
                DispatchQueue.main.async {
                    self.changelog = decodedData
                }
            } catch {
                print("Failed to decode changelog: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func setupBackgroundNotification() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if self.routeInNavigation == nil {
                    BeaconTTSService.shared.speak(String(localized: "Orinav is running in the background."), type: .navigation)
                } else {
                    BeaconTTSService.shared.speak(String(localized: "Orinav is navigating in the background."), type: .navigation)
                }
            }
        }
    }
}

public enum BeaconPage: String, CaseIterable, Codable {
    case poi        = "poi"
    case routes     = "routes"
    case navigation = "navigation"
}
