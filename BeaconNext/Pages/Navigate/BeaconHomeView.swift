import SwiftUI
import QMapKit

struct BeaconHomeView: View {
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @EnvironmentObject var globalUIState: BeaconGlobalUIState
    
    @State private var isShowingSearch = false
    
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .accessibilityHidden(true)
                            Text(globalState.locationDelegate.currentLocation?.bName ?? "Loading...") // Current Location
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Current Location: \(globalState.locationDelegate.currentLocation?.bName ?? "Loading...")")

                        Button(action: {
                            isShowingSearch = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                Text("Search for a place or address")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(8)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.secondary.opacity(0.2))
                        )
                        .accessibilityLabel("Search")
                        .accessibilityAddTraits(.isSearchField)
                        .accessibilityHint("Tap to open search")
                    }
                }
                
                // MARK: Favorites View
                VStack(alignment: .leading, spacing: 16) {
                    Text("Favorites")
                        .font(.title2)
                        .bold()
                    
                    if favoritesManager.favorites.isEmpty {
                        Text("No favorites yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(favoritesManager.favorites, id: \.bid) { poi in
                                    FavoriteCardView(
                                        poi: poi,
                                        onDelete: {
                                            favoritesManager.removeFavorite(id: poi.bid)
                                            BeaconTTSService.shared.speak(poi.bName, language: "zh-CN")
                                            BeaconTTSService.shared.speak("deleted from favorites")
                                        },
                                        onTap: {
                                            globalUIState.choosingRoutes = true
                                            globalUIState.from = nil
                                            globalUIState.destination = poi
                                        }
                                    )
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                }


                // MARK: Beacon Promotion?
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
                        PromotionCardView(
                            title: "Latest Features",
                            text: "Android support, road orientation, and more!",
                            color: .cyan
                        )
                        PromotionCardView(
                            title: "New to Beacon?",
                            text: "Start a tutorial to learn about how easy Beacon is.",
                            color: .blue
                        )
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $isShowingSearch) {
            BeaconSearchView(isPresented: $isShowingSearch) { poi in
                globalUIState.from = nil
                globalUIState.destination = poi
                globalUIState.choosingRoutes = true
            }
        }
        .sheet(isPresented: $globalUIState.choosingRoutes) {
            BeaconRouteSelectionView(from: $globalUIState.from, destination: $globalUIState.destination, isPresented: $globalUIState.choosingRoutes)
        }
        .navigationTitle("Beacon")
        .navigationBarTitleDisplayMode(.large)
    }
}
