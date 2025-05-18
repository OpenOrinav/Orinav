import SwiftUI
import UIKit
import QMapKit
import TencentNavKit
import TNKAudioPlayer

struct BeaconRouteCardView: View {
    let route: TNKWalkRoute

    @State private var isPresentingNavigation = false

    @EnvironmentObject var navManager: BeaconNavigationDelegateSimple

    private var timeText: String {
        let minutes = Int(route.totalTime)
        let hours = minutes / 60
        return "\(hours > 0 ? "\(hours) hr " : "")\(minutes % 60) min"
    }

    private var distanceText: String {
        if route.totalDistance < 100 {
            let rounded = (route.totalDistance / 10) * 10
            return "\(rounded) m"
        } else {
            let km = Double(route.totalDistance) / 1000.0
            return String(format: "%.1f km", km)
        }
    }

    private var subtitleText: String {
        "\(distanceText) · \(route.segmentItems.count) turns"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeText)
                    .font(.title2)
                    .accessibilityLabel("Route: \(timeText) estimated")
                    .bold()
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("GO") {
                isPresentingNavigation = true
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
        .fullScreenCover(isPresented: $isPresentingNavigation) {
            BeaconNavigationView(navManager: navManager, selectedRoute: route)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

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
    @Binding var from: QMSPoiData?
    @Binding var destination: QMSPoiData?
    @Binding var isPresented: Bool
    @State private var isShowingSearchForFrom = false
    @State private var isShowingSearchForDestination = false

    @EnvironmentObject var locationManager: BeaconLocationDelegateSimple
    @EnvironmentObject var navManager: BeaconNavigationDelegateSimple
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Directions")
                .font(.title)
                .bold()
            
            // From/destination selection
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    BeaconIconConnector(
                        topImage: Image(systemName: from == nil ? "location.circle.fill" : BeaconUIUtils.iconName(for: from!.category_code)),
                        topColor: from == nil ? .blue : BeaconUIUtils.iconColor(for: from!.category_code),
                        bottomImage: Image(systemName: destination == nil ? "location.circle.fill" : BeaconUIUtils.iconName(for: destination!.category_code)),
                        bottomColor: destination == nil ? .blue : BeaconUIUtils.iconColor(for: destination!.category_code)
                    )
                    VStack(spacing: 12) {
                        // From text
                        Button {
                            isShowingSearchForFrom = true
                        } label: {
                            Text(from?.title ?? "My Location")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: from) {
                            handleSearch()
                        }
                        .accessibilityLabel("Starting location")
                        .accessibilityValue(from?.title ?? "My Location")
                        .accessibilityHint("Double tap to select a starting point")
                        
                        Divider()
                            .accessibilityHidden(true)
                        
                        // Destination text
                        Button {
                            isShowingSearchForDestination = true
                        } label: {
                            Text(destination?.title ?? "My Location")
                                .font(.body)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: destination) {
                            handleSearch()
                        }
                        .accessibilityLabel("Destination")
                        .accessibilityValue(destination?.title ?? "My Location")
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
            if navManager.searchLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .accessibilityLabel("Loading routes")
            } else if navManager.lastSearchResults.count > 0 {
                LazyVStack(spacing: 16) {
                    ForEach(navManager.lastSearchResults, id: \.routeID) { route in
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
        navManager.planRoutes(from: from, to: destination, location: locationManager.lastLocation?.coordinate)
    }
}

struct BeaconNavigationView: UIViewRepresentable {
    let navManager: BeaconNavigationDelegateSimple
    let selectedRoute: TNKWalkRoute
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        navManager.navView = TNKWalkNavView(frame: UIScreen.main.bounds)
        view.addSubview(navManager.navView!)
        navManager.navView!.showUIElements = true
        navManager.navView!.delegate = navManager
        navManager.navManager.register(navManager.navView!)
        
        navManager.startNavigation(with: selectedRoute)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
