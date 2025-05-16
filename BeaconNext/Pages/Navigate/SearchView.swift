import SwiftUI
import AMapSearchKit

struct SearchView: View {
    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var locationManager: BeaconLocationDelegateSimple
    @EnvironmentObject private var searchManager: BeaconSearchDelegateSimple
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                TextField("Search for a place or address", text: $searchText)
                    .foregroundColor(.secondary)
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
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.secondary.opacity(0.2))
            )
        }
        .accessibilityAction(.escape) {
            dismiss()
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
        .overlay(
            Button {
                dismiss()
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
        self.searchManager.search(request)
    }
}

#Preview {
    SearchView()
}
