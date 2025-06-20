import Foundation
import SwiftUI

struct BeaconPOIView: View {
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @EnvironmentObject var globalUIState: BeaconGlobalUIState
    
    @State private var poiTime: Int? = nil
    @State private var isFavorited: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(globalUIState.poi?.bName ?? "...")
                    .font(.title)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .bold()
                
                Spacer()
                
                if let poi = globalUIState.poi {
                    Button {
                        if isFavorited {
                            FavoritesManager.shared.removeFavorite(id: poi.bid)
                        } else {
                            FavoritesManager.shared.addFavorite(poi: poi)
                        }
                        isFavorited.toggle()
                    } label: {
                        Image(systemName: "star.circle.fill")
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
            
            Button {
                if let poi = globalUIState.poi {
                    globalUIState.routesFrom = nil
                    globalUIState.routesDestination = poi
                    globalUIState.currentPage = .routes
                }
            } label: {
                Text("Walk · \(poiTime == nil ? "..." : String(poiTime!)) \(poiTime == 1 ? "minute" : "minutes")")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(globalUIState.poi == nil)
            .accessibilityLabel("Start walk navigation, takes \(poiTime == nil ? "..." : String(poiTime!)) \(poiTime == 1 ? "minute" : "minutes")")
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Address")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(globalUIState.poi!.bAddress)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(globalUIState.poi!.bCategory.rawValue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
            )
        }
        .onAppear {
            findPOITime()
            if let poi = globalUIState.poi {
                isFavorited = FavoritesManager.shared.favorites.contains { $0.bid == poi.bid }
            }
        }
        .accessibilityAction(.escape) {
            globalUIState.currentPage = nil
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .background(.ultraThickMaterial)
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
