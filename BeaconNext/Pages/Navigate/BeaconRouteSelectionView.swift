import SwiftUI
import UIKit

struct BeaconIconConnector: View {
    let topImage: Image
    let topColor: Color
    let bottomImage: Image
    let bottomColor: Color
    
    var body: some View {
        VStack(spacing: 6) {
            topImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(topColor)
                .accessibilityHidden(true)
            VStack(spacing: 2) {
                Circle().frame(width: 2, height: 2).foregroundStyle(.secondary)
                Circle().frame(width: 2, height: 2).foregroundStyle(.secondary)
                Circle().frame(width: 2, height: 2).foregroundStyle(.secondary)
            }
            bottomImage
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(bottomColor)
                .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
    }
}

struct BeaconRouteSelectionView: View {
    @State private var isShowingSearchForFrom = false
    @State private var isShowingSearchForDestination = false
    @State private var searchLoading = false
    @State private var searchResults: [any BeaconWalkRoute] = []
    
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @EnvironmentObject var globalUIState: BeaconGlobalUIState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Directions")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button {
                    globalUIState.currentPage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Close")
                .accessibilityHint("Dismisses the route selection sheet")
            }
            
            // From/destination selection
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    BeaconIconConnector(
                        topImage: Image(systemName: globalUIState.routesFrom == nil ? "location.circle.fill" : globalUIState.routesFrom!.bIcon),
                        topColor: globalUIState.routesFrom == nil ? .blue : globalUIState.routesFrom!.bIconColor,
                        bottomImage: Image(systemName: globalUIState.routesDestination == nil ? "location.circle.fill" : globalUIState.routesDestination!.bIcon),
                        bottomColor: globalUIState.routesDestination == nil ? .blue : globalUIState.routesDestination!.bIconColor
                    )
                    VStack(spacing: 12) {
                        // From text
                        Button {
                            isShowingSearchForFrom = true
                        } label: {
                            Text(globalUIState.routesFrom?.bName ?? "My Location")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: globalUIState.routesFrom?.bid) {
                            handleSearch()
                        }
                        .accessibilityLabel("Starting location")
                        .accessibilityValue(globalUIState.routesFrom?.bName ?? "My Location")
                        .accessibilityHint("Double tap to select a starting point")
                        
                        Divider()
                            .accessibilityHidden(true)
                        
                        // Destination text
                        Button {
                            isShowingSearchForDestination = true
                        } label: {
                            Text(globalUIState.routesDestination?.bName ?? "My Location")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: globalUIState.routesDestination?.bid) {
                            handleSearch()
                        }
                        .accessibilityLabel("Destination")
                        .accessibilityValue(globalUIState.routesDestination?.bName ?? "My Location")
                        .accessibilityHint("Double tap to select destination")
                    }
                    Button {
                        let oldFrom = globalUIState.routesFrom
                        globalUIState.routesFrom = globalUIState.routesDestination
                        globalUIState.routesDestination = oldFrom
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel("Swap start and destination")
                    .accessibilityHint("Double tap to swap your starting point and destination")
                    
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            
            // Routes list / loading / empty state
            if searchLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .accessibilityLabel("Loading routes")
            } else if searchResults.count > 0 {
                LazyVStack(spacing: 16) {
                    ForEach(searchResults, id: \.bid) { route in
                        BeaconRouteCardView(route: route)
                    }
                }
            } else {
                Text("No routes found")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            handleSearch()
        }
        .sheet(isPresented: $isShowingSearchForFrom) {
            BeaconSearchView(
                isPresented: $isShowingSearchForFrom,
                showCurrentLocation: true
            ) { poi in
                globalUIState.routesFrom = poi
            }
        }
        .sheet(isPresented: $isShowingSearchForDestination) {
            BeaconSearchView(
                isPresented: $isShowingSearchForDestination,
                // Never allow destination to be My Location
            ) { poi in
                globalUIState.routesDestination = poi
            }
        }
        .accessibilityAction(.escape) {
            globalUIState.currentPage = nil
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .background(.ultraThickMaterial)
    }
    
    private func handleSearch() {
        searchLoading = true
        Task {
            let results = await globalState.navigationProvider
                .planRoutes(
                    from: globalUIState.routesFrom,
                    to: globalUIState.routesDestination,
                    location: globalState.locationProvider.currentLocation!
                )
            await MainActor.run {
                searchResults = results
                searchLoading = false
            }
        }
    }
}
