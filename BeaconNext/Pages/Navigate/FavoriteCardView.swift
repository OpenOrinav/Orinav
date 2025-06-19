import SwiftUI
import QMapKit

struct FavoriteCardView: View {
    let poi: any BeaconPOI
    let onDelete: () -> Void
    let onTap: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    Image(systemName: poi.bIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(poi.bIconColor)

                    Text(poi.bName)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(width: 100, height: 100)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(.plain)

            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
            .accessibilityLabel("Remove \(poi.bName) from favorites")
        }
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
