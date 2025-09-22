import SwiftUI
import QMapKit

struct BeaconHomeView: View {
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @EnvironmentObject var globalUIState: BeaconGlobalUIState
    
    @State private var isShowingSearch = false
    @State private var isShowingIntro = false
    @State private var isShowingChangelog = false
    
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .accessibilityHidden(true)
                            if let name = globalState.locationDelegate.currentLocation?.bName {
                                Text(name) // Current Location
                                    .font(.headline)
                            } else {
                                Text("Loading...")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            globalState.locationDelegate.currentLocation?.bName == nil ? "Current Location: Loading..." : "Current Location: \(globalState.locationDelegate.currentLocation!.bName!)"
                        )

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
                VStack(alignment: .leading, spacing: favoritesManager.favorites.isEmpty ? 0 : 16) {
                    Text("Favorites")
                        .font(.title2)
                        .bold()
                    
                    if favoritesManager.favorites.isEmpty {
                        Text("No favorites yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.vertical) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(favoritesManager.favorites, id: \.bid) { poi in
                                    FavoriteCardView(
                                        poi: poi,
                                        onDelete: {
                                            favoritesManager.removeFavorite(id: poi.bid)
                                        },
                                        onTap: {
                                            globalUIState.poi = poi
                                            globalUIState.currentPage = .poi
                                        }
                                    )
                                }
                            }
                            .padding(.top, 6)
                        }
                        .frame(maxHeight: 200)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Welcome to Orinav")
                            .font(.title2)
                            .bold()
                        Text("A set of notes to help you get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        if let changelog = globalUIState.changelog {
                            PromotionCardView(
                                title: "What's New in Orinav",
                                text: "Version \(changelog.version) · \(Date(timeIntervalSince1970: TimeInterval(changelog.timestamp)).formatted(date: .abbreviated, time: .omitted))",
                                color: .accentColor
                            ) {
                                isShowingChangelog = true
                            }
                        }
                        
                        PromotionCardView(
                            title: "New to Orinav?",
                            text: "Start a tutorial to learn the basics",
                            color: .pink
                        ) {
                            isShowingIntro = true
                        }
                    }
                }
            }
            .padding()
        }
        // Present pages
        .sheet(isPresented: $isShowingSearch) {
            BeaconSearchView(isPresented: $isShowingSearch) { poi in
                globalUIState.poi = poi
                globalUIState.currentPage = .poi
            }
        }
        .sheet(isPresented: createBinding(.poi)) {
            BeaconPOIView()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: createBinding(.routes)) {
            BeaconRouteSelectionView()
        }
        .fullScreenCover(isPresented: createBinding(.navigation)) {
            BeaconNavigationContainerView()
                .ignoresSafeArea(edges: .all)
        }
        
        // Present intro
        .sheet(isPresented: $isShowingIntro) {
            BeaconIntroView(isPresented: $isShowingIntro)
                .presentationDetents([.large])
                .interactiveDismissDisabled(!SettingsManager.shared.shownIntro) // Compliance: Must agree to terms before continuing
        }
        
        // Present changelog
        .sheet(isPresented: $isShowingChangelog) {
            BeaconChangelogView(isPresented: $isShowingChangelog, changelog: globalUIState.changelog!)
        }
        
        // Present permissions popup
        .sheet(isPresented: Binding(
            get: { globalState.locationDelegate.authorizationStatus == .denied || globalState.locationDelegate.authorizationStatus == .restricted },
            set: { _ in }
        )) {
            BeaconPermissionsView()
                .interactiveDismissDisabled()
        }
        
        // Show intro if necessary
        .onAppear {
            if !SettingsManager.shared.shownIntro {
                isShowingIntro = true
            }
        }
        
        // Show changelog if necessary
        .onChange(of: globalUIState.changelog) {
            guard let changelog = globalUIState.changelog else { return }
            if !SettingsManager.shared.shownIntro {
                // Skip changelog on initial installation
                SettingsManager.shared.lastShownChangelog = changelog.timestamp
                return
            }
            
            if SettingsManager.shared.lastShownChangelog != changelog.timestamp {
                // Show if changelog has been updated
                isShowingChangelog = true
                SettingsManager.shared.lastShownChangelog = changelog.timestamp
            }
        }
        
        // Titles
        .navigationTitle("Orinav")
        .navigationBarTitleDisplayMode(.large)
    }
    
    func createBinding(_ page: BeaconPage) -> Binding<Bool> {
        Binding(
            get: { globalUIState.currentPage == page },
            set: { isPresented in
                if isPresented {
                    globalUIState.currentPage = page
                } else {
                    globalUIState.currentPage = nil
                }
            }
        )
    }
}
