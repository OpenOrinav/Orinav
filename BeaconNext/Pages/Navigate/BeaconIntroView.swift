import SwiftUI

struct BeaconIntroView: View {
    @Binding var isPresented: Bool
    
    // TODO: Rework
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title: "Welcome to Orinav"
                
                Text("Welcome to Orinav")
                    .font(.title)
                    .bold()
                
                
                Text("Orinav is a new navigation app designed for individuals with visual impairments. It provides intuitive navigation features to help you get around safely.")
                Text("To get started navigating, simply search for places or addresses. While navigating, you will hear instructions to orient yourself to the road. Shake to repeat instructions.")
                Text("Enter the Explore tab to learn more about your environment, including recognizing traffic lights, objects, and obstacles. While navigating, raise your phone to enter Explore mode.")
                Text("Keep your phone pointing straight forward. When using Explore, keep your phone upright, at chest level, and pointing straight ahead.")
                Text("Orinav is not a medical device. Orinav should not be used as a sole means of navigation and does not replace service animals, mobility aids, orientation and mobility training, or professional medical and safety advice. You remain responsible for your own safety.")
                Text("You can return to this introduction at any time from the home page.")
                Text("By continuing, you indicate your agreement to Orinav's [Terms of Service](\("https://orinav.com/terms")) and [Privacy Policy](\("https://orinav.com/privacy")).") // Links separated to allow for localization
                
                Button("Agree and Continue") {
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
