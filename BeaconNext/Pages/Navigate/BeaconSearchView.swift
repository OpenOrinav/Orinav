import SwiftUI
import QMapKit
import CoreLocation

struct BeaconSearchView: View {
    @State private var searchText: String = ""
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var searchResults: [any BeaconPOI] = []
    @FocusState private var isSearchFieldFocused: Bool
    @Binding var isPresented: Bool
    var showCurrentLocation: Bool = false
    var onSelect: ((any BeaconPOI)?) -> Void
    
    @EnvironmentObject var globalState: BeaconMappingCoordinator
    
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
                            searchResults = []
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
                searchResults = []
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.2))
            )
            
            if showCurrentLocation && searchResults.isEmpty {
                HStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.accent)
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
            
            if !searchResults.isEmpty {
                List($searchResults, id: \.bid) { poi in
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: poi.wrappedValue.bIcon)
                            .font(.system(size: 36))
                            .foregroundColor(poi.wrappedValue.bIconColor)
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(poi.wrappedValue.bName)
                                .font(.headline)
                            if globalState.locationProvider.currentLocation != nil,
                               let dist = globalState.locationProvider.currentLocation?.distance(to: poi.wrappedValue.bCoordinate) {
                                Text("\(BeaconUIUtils.formattedDistance(dist)) · \(poi.wrappedValue.bAddress)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            } else {
                                Text(poi.wrappedValue.bAddress)
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
                        onSelect(poi.wrappedValue)
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
            searchResults = []
            return
        }
        Task {
            let results = await globalState.searchProvider.searchByPOI(
                poi: text,
                center: globalState.locationProvider.currentLocation?.bCoordinate
            )
            await MainActor.run {
                searchResults = results
            }
        }
    }
}
