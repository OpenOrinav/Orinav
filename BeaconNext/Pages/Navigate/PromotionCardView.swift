import SwiftUI

struct PromotionCardView: View {
    let title: LocalizedStringResource
    let text: LocalizedStringResource
    let color: Color
    var onTap: () -> Void = {}

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
        .scaleEffect(isPressed ? 0.95 as CGFloat : 1.0 as CGFloat)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                onTap()
            }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(text)")
        .accessibilityAddTraits(.isButton)
    }
}
