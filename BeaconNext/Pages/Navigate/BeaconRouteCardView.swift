import SwiftUI

struct BeaconRouteCardView: View {
    let route: any BeaconWalkRoute

    @EnvironmentObject var globalState: BeaconMappingCoordinator
    @EnvironmentObject var globalUIState: BeaconGlobalUIState

    private var timeText: String {
        let minutes = route.bTimeMinutes
        let hours = minutes / 60
        return "\(hours > 0 ? "\(hours) hr " : "")\(minutes % 60) min"
    }

    private var distanceText: String {
        if route.bDistanceMeters < 100 {
            let rounded = (route.bDistanceMeters / 10) * 10
            return "\(rounded) m"
        } else {
            let km = Double(route.bDistanceMeters) / 1000.0
            return String(format: "%.1f km", km)
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeText)
                    .font(.title2)
                    .accessibilityLabel("Route: \(timeText) estimated")
                    .bold()
                Text(distanceText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("GO") {
                globalUIState.routeInNavigation = route
                globalUIState.currentPage = .navigation
            }
            .font(.body)
            .bold()
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            .accessibilityLabel("Go")
            .accessibilityHint("Start navigation for this route")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
        )
    }
}
