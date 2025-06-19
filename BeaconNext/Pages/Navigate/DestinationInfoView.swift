import SwiftUI
import QMapKit

struct DestinationInfoView: View {
    let poi: QMSPoiData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(poi.title)
                .font(.title)
                .bold()
                .padding(.bottom, 12)

            Text(poi.address)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(String(format: "Lat: %.4f, Lng: %.4f", poi.location.latitude, poi.location.longitude))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
