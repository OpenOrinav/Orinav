import SwiftUI

struct HomeView: View {
    @EnvironmentObject var locationManager: BeaconLocationDelegateSimple
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .accessibilityHidden(true)
                            Text(locationManager.lastAddress?.poiName ?? "Loading...") // Current Location
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current Location: \(locationManager.lastAddress?.poiName ?? "Loading...")")
                        NavigationLink(destination: SettingsView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                Text("Search for a place or address")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.secondary.opacity(0.2))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Search")
                        .accessibilityAddTraits(.isSearchField)
                        .accessibilityHint("Tap to open search")
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Favorites")
                        .font(.title2)
                        .bold()
                    HStack(spacing: 16) {
                        FavoriteView(
                            text: "Home",
                            subtitle: "Close by",
                            fullSubtitle: "Close by",
                            icon: "house.circle.fill"
                        )
                        FavoriteView(
                            text: "School",
                            subtitle: "31m",
                            fullSubtitle: "31 minutes",
                            icon: "graduationcap.circle.fill"
                        )
                        FavoriteView(
                            text: "World",
                            subtitle: "999h",
                            fullSubtitle: "999 hours",
                            icon: "mappin.circle.fill"
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Welcome to Beacon")
                            .font(.title2)
                            .bold()
                        Text("A set of notes to help you get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        CardView(
                            title: "Latest Features",
                            text: "Android support, road orientation, and more!",
                            color: .cyan
                        )
                        CardView(
                            title: "New to Beacon?",
                            text: "Start a tutorial to learn about how easy Beacon is.",
                            color: .blue
                        )
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Beacon")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    HomeView()
}
