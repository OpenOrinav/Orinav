import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                BeaconHomeView()
            }
            .tabItem {
                Image(systemName: "map")
                Text("Navigate")
            }

            NavigationView {
                BeaconExploreView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Explore")
            }

            NavigationView {
                BeaconSettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
}

#Preview {
    ContentView()
}
