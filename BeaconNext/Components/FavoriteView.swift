//
//  FavoriteView.swift
//  BeaconNext
//
//  Created by Dreta ​ on 5/15/25.
//

import SwiftUI

struct FavoriteView: View {
    let text: String
    let subtitle: String
    let fullSubtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(.blue)
            VStack(spacing: 0) {
                Text(text)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(text): \(fullSubtitle)")
    }
}
