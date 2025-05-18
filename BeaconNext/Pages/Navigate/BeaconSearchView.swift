import SwiftUI
import QMapKit
import CoreLocation

struct BeaconSearchView: View {
    @State private var searchText: String = ""
    @State private var debounceWorkItem: DispatchWorkItem?
    @FocusState private var isSearchFieldFocused: Bool
    @Binding var isPresented: Bool
    var showCurrentLocation: Bool = false
    var onSelect: (QMSPoiData?) -> Void
    
    @EnvironmentObject private var locationManager: BeaconLocationDelegateSimple
    @EnvironmentObject private var searchManager: BeaconSearchDelegateSimple
    
    private func calculateDistance(to coord: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let userLocation = locationManager.lastLocation else { return nil }
        let poiLocation = CLLocation(
            latitude: coord.latitude,
            longitude: coord.longitude
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
                    .onChange(of: searchText) {
                        debounceWorkItem?.cancel()
                        guard searchText.count >= 1 else {
                            searchManager.resetSearch()
                            return
                        }
                        let work = DispatchWorkItem {
                            performSearch(searchText)
                        }
                        debounceWorkItem = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                    }
                    .focused($isSearchFieldFocused)
                    .accessibilityLabel("Search for a place or address")
                    .accessibilityAddTraits(.isSearchField)
                    .accessibilityHint("Type to search for a place or address")
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
                List(searchManager.lastSearchResults, id: \.id_) { poi in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: BeaconUIUtils.iconName(for: poi.category_code))
                            .font(.system(size: 36))
                            .foregroundColor(BeaconUIUtils.iconColor(for: poi.category_code))
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(poi.title)
                                .font(.headline)
                            if locationManager.lastLocation != nil,
                               let dist = calculateDistance(to: poi.location) {
                                Text("\(BeaconUIUtils.formattedDistance(dist)) · \(poi.address)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                Text(poi.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
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
    
    private func performSearch(_ text: String) {
        guard text.count >= 1 else {
            // clear results if too short
            searchManager.resetSearch()
            return
        }
        searchManager.searchPOIByKeywords(
            text,
            center: locationManager.lastLocation?.coordinate
        )
    }
}
