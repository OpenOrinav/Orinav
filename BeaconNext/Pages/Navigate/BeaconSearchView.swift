import SwiftUI
import AMapSearchKit
import CoreLocation

struct BeaconSearchView: View {
    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    @Binding var isPresented: Bool
    var showCurrentLocation: Bool = false
    var onSelect: (AMapPOI?) -> Void
    
    @EnvironmentObject private var locationManager: BeaconLocationDelegateSimple
    @EnvironmentObject private var searchManager: BeaconSearchDelegateSimple
    
    private func calculateDistance(to geoPoint: AMapGeoPoint) -> CLLocationDistance? {
        guard let userLocation = locationManager.lastLocation else { return nil }
        let poiLocation = CLLocation(
            latitude: geoPoint.latitude,
            longitude: geoPoint.longitude
        )
        return userLocation.distance(from: poiLocation)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                TextField("Search for a place or address", text: $searchText)
                    .focused($isSearchFieldFocused)
                    .accessibilityLabel("Search for a place or address")
                    .accessibilityAddTraits(.isSearchField)
                    .accessibilityHint("Type to search for a place or address")
                    .onChange(of: searchText) {
                        handleSearch()
                    }
            }
            .onAppear {
                isSearchFieldFocused = true
                searchManager.resetSearch()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.2))
            )
            
            if showCurrentLocation && searchManager.lastSearchResults.isEmpty {
                HStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Location")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(nil)
                    isPresented = false
                }
            }
            
            if !searchManager.lastSearchResults.isEmpty {
                List(searchManager.lastSearchResults, id: \.uid) { poi in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: BeaconUIUtils.iconName(for: poi.typecode))
                            .font(.system(size: 36))
                            .foregroundColor(BeaconUIUtils.iconColor(for: poi.typecode))
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            if let name = poi.name {
                                Text(name)
                                    .font(.headline)
                            }
                            if let address = poi.address {
                                if let geoPoint = poi.location,
                                   let dist = calculateDistance(to: geoPoint) {
                                    Text("\(BeaconUIUtils.formattedDistance(dist)) · \(address)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                } else {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(poi)
                        isPresented = false
                    }
                }
                .listStyle(.plain)
            } else {
                Spacer()
            }
        }
        .accessibilityAction(.escape) {
            isPresented = false
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .overlay(
            Button {
                isPresented = false
            } label: {
                EmptyView()
            }
                .accessibilityLabel("Close")
                .accessibilityHint("Dismisses the search sheet")
        )
    }
    
    private func handleSearch() {
        let request = AMapPOIKeywordsSearchRequest()
        request.keywords = searchText
        if let location = locationManager.lastLocation {
            request.location = AMapGeoPoint.location(
                withLatitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        self.searchManager.searchPOIByKeywords(request)
    }
}
