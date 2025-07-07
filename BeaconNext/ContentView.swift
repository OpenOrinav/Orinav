import SwiftUI

struct ContentView: View {
    @State private var selection: Int = 0
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                BeaconHomeView()
            }
            .tabItem {
                Image(systemName: "map")
                Text("Navigate")
            }
            .tag(0)

            NavigationView {
                if selection == 1 {
                    BeaconExploreView()
                }
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Explore")
            }
            .tag(1)

            NavigationView {
                BeaconSettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
