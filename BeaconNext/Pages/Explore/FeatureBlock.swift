import SwiftUI
import UIKit

struct FeatureBlock: View {
    var icon: String
    var name: LocalizedStringResource
    var active: Binding<Bool>
    
    var body: some View {
        Button(action: {
            active.wrappedValue.toggle()
        }) {
            VStack(alignment: .leading) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .bold()
                    Text(active.wrappedValue ? "Enabled" : "Disabled")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .foregroundColor(active.wrappedValue ? Color.white : Color.primary)
        .background(active.wrappedValue ? Color.blue : Color(UIColor.systemBackground))
        .cornerRadius(24)
        .buttonStyle(PlainButtonStyle())
    }
}
