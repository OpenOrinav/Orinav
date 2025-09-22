import SwiftUI

struct ChangelogData: Codable, Equatable {
    var version: String
    var timestamp: Int
    var content: String
}

struct BeaconChangelogView: View {
    @Binding var isPresented: Bool
    
    var changelog: ChangelogData
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("What's New in Orinav")
                    .font(.title)
                    .bold()
                
                Text("Version \(changelog.version) · \(Date(timeIntervalSince1970: TimeInterval(changelog.timestamp)).formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(changelog.content)
                
                
                Button("Continue") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }
}
