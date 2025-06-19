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
    @Binding var from: (any BeaconPOI)?
    @Binding var destination: (any BeaconPOI)?
    @Binding var isPresented: Bool
    
    @State private var isShowingSearchForFrom = false
    @State private var isShowingSearchForDestination = false
    @State private var searchLoading = false
    @State private var searchResults: [any BeaconWalkRoute] = []
    
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Directions")
                .font(.title)
                .bold()
            
            // From/destination selection
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    BeaconIconConnector(
                        topImage: Image(systemName: from == nil ? "location.circle.fill" : from!.bIcon),
                        topColor: from == nil ? .blue : from!.bIconColor,
                        bottomImage: Image(systemName: destination == nil ? "location.circle.fill" : destination!.bIcon),
                        bottomColor: destination == nil ? .blue : destination!.bIconColor
                    )
                    VStack(spacing: 12) {
                        // From text
                        Button {
                            isShowingSearchForFrom = true
                        } label: {
                            Text(from?.bName ?? "My Location")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: from?.bid) {
                            handleSearch()
                        }
                        .accessibilityLabel("Starting location")
                        .accessibilityValue(from?.bName ?? "My Location")
                        .accessibilityHint("Double tap to select a starting point")
                        
                        Divider()
                            .accessibilityHidden(true)
                        
                        // Destination text
                        Button {
                            isShowingSearchForDestination = true
                        } label: {
                            Text(destination?.bName ?? "My Location")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: destination?.bid) {
                            handleSearch()
                        }
                        .accessibilityLabel("Destination")
                        .accessibilityValue(destination?.bName ?? "My Location")
                        .accessibilityHint("Double tap to select destination")
                    }
                    Button {
                        let oldFrom = from
                        from = destination
                        destination = oldFrom
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
                from = poi
            }
        }
        .sheet(isPresented: $isShowingSearchForDestination) {
            BeaconSearchView(
                isPresented: $isShowingSearchForDestination,
                // Never allow destination to be My Location
            ) { poi in
                destination = poi
            }
        }
        .accessibilityAction(.escape) {
            isPresented = false
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.secondarySystemBackground))
        .overlay(
            Button {
                isPresented = false
            } label: {
                EmptyView()
            }
                .accessibilityLabel("Close")
                .accessibilityHint("Dismisses the route selection sheet")
        )
    }
    
    private func handleSearch() {
        searchLoading = true
        Task {
            let results = await globalState.navigationProvider
                .planRoutes(
                    from: from,
                    to: destination,
                    location: globalState.locationProvider.currentLocation!
                )
            await MainActor.run {
                searchResults = results
                searchLoading = false
            }
        }
    }
}
