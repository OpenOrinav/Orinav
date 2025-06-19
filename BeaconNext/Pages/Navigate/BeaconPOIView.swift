import Foundation
import SwiftUI

struct BeaconPOIView: View {
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @EnvironmentObject var globalUIState: BeaconGlobalUIState
    
    @State private var poiTime: Int? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(globalUIState.poi?.bName ?? "...")
                    .font(.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .bold()
                
                if let poi = globalUIState.poi {
                    let isFavorited = FavoritesManager.shared.favorites.contains { $0.bid == poi.bid }
                    Button {
                        if isFavorited {
                            FavoritesManager.shared.removeFavorite(id: poi.bid)
                        } else {
                            FavoritesManager.shared.addFavorite(poi: poi)
                        }
                    } label: {
                        Image(systemName: isFavorited ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isFavorited ? .yellow : .secondary)
                    }
                    .accessibilityLabel(isFavorited ? "Remove from Favorites" : "Add to Favorites")
                    .accessibilityHint(isFavorited ? "Removes this POI from your favorites" : "Adds this POI to your favorites")
                }
                
                Button {
                    globalUIState.currentPage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Close")
                .accessibilityHint("Dismisses the POI sheet")
            }
            
            Button("Walk · \(poiTime == nil ? "..." : String(poiTime!)) \(poiTime == 1 ? "minute" : "minutes")") {
                if let poi = globalUIState.poi {
                    globalUIState.routesFrom = nil
                    globalUIState.routesDestination = poi
                    globalUIState.currentPage = .routes
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .frame(maxWidth: .infinity)
            .disabled(globalUIState.poi == nil)
            .accessibilityLabel("Start navigation")
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 4) {
                    Text("Address")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(globalUIState.poi!.bAddress)
                }
                
                VStack(spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(globalUIState.poi!.bCategory.rawValue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
        }
        .onAppear {
            findPOITime()
        }
        .accessibilityAction(.escape) {
            globalUIState.currentPage = nil
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    func findPOITime() {
        Task {
            let results = await globalState.navigationProvider
                .planRoutes(
                    from: nil,
                    to: globalUIState.poi!,
                    location: globalState.locationProvider.currentLocation!
                )
            await MainActor.run {
                poiTime = results.first?.bTimeMinutes
            }
        }
    }
}

