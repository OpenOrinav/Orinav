//
//  InitiateNavigateView.swift
//  BeaconNext
//
//  Created by Dreta ​ on 5/15/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Start Navigating")
                    .font(.title2)
                    .bold()
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .accessibilityHidden(true)
                        Text("Lorem Ipsum") // Current Location
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Current Location: Lorem Ipsum")
                    NavigationLink(destination: SettingsView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            Text("Search for a place or address")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(.secondary.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Search")
                    .accessibilityAddTraits(.isSearchField)
                    .accessibilityHint("Tap to open search")
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome to Beacon")
                        .font(.title2)
                        .bold()
                    Text("A set of notes to help you get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 16) {
                    CardView(
                        title: "Latest Features",
                        text: "Android support, road orientation, and more!",
                        color: .cyan
                    )
                    CardView(
                        title: "New to Beacon?",
                        text: "Start a tutorial to learn about how easy Beacon is.",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle("Beacon")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    HomeView()
}
