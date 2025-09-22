import SwiftUI
import QMapKit

struct FavoriteCardView: View {
    let poi: any BeaconPOI
    let onDelete: () -> Void
    let onTap: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: poi.bIcon)
                    .font(.system(size: 48, weight: .regular))
                    .foregroundColor(poi.bIconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(poi.bName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(poi.bCategory.localizedName)
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
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Text("Delete")
            }
        }
        .buttonStyle(.plain)
        .alert("Delete from favorites?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(poi.bName)\" from your favorites?")
        }
    }
}
