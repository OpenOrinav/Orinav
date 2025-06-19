import SwiftUI
import QMapKit

struct FavoriteCardView: View {
    let poi: any BeaconPOI
    let onDelete: () -> Void
    let onTap: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Image(systemName: poi.bIcon)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(poi.bIconColor)
                VStack(spacing: 0) {
                    Text(poi.bName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(poi.bCategory.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(poi.bName)
        }
        .contextMenu {
            Button("Delete", action: { showDeleteAlert = true })
                .foregroundColor(.red)
        }
        .buttonStyle(.plain)
        .alert("Remove from favorites?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \"\(poi.bName)\" from your favorites?")
        }
    }
}
