//
//  CardView.swift
//  BeaconNext
//
//  Created by Dreta ​ on 5/15/25.
//

import SwiftUI

struct CardView: View {
    let title: LocalizedStringResource
    let text: LocalizedStringResource
    let color: Color

    @GestureState private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
            Text(text)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(color)
                .shadow(color: color.opacity(0.3), radius: 8)
        )
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
    }
}
