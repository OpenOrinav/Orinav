import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView {
                HomeView()
            }
            .tabItem {
                Image(systemName: "map")
                Text("Navigate")
            }

            NavigationView {
                ExploreView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Explore")
            }

            NavigationView {
                SettingsView()
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
