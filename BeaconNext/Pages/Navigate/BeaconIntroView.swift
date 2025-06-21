import SwiftUI

struct BeaconIntroView: View {
    @State var currentPage = 0
    @Binding var isPresented: Bool
    
    private let pages = [
        String(localized: "Welcome to Beacon"),
        String(localized: "Navigate effortlessly"),
        String(localized: "Explore the world"),
        String(localized: "Stay informed"),
        String(localized: "Let's start from here")
    ]
    private let contents = [
        String(localized: "Beacon is a new navigation app designed for individuals with visual impairments. It provides intuitive navigation features to help you get around safely."),
        String(localized: "To get started navigating, simply search for places or addresses. While navigating, you can shake your device to hear instructions. You can also raise your device for environment awareness, such as learning about obstacles and traffic lights."),
        String(localized: "Enter the Explore tab to hear nearby places as you go. You can also raise your device for the same environment awareness feature."),
        String(localized: "Beacon is not a medical device. Beacon should not be used as a sole means of navigation and does not replace service animals, mobility aids, or professional medical or safety advice. You remain responsible for your own safety."),
        String(localized: "You can always return to this introduction by tapping the tutorial card on the home page.")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pages[index])
                            .font(.title)
                            .bold()
                            .tag(index)
                        Text(contents[index])
                    }
                    .padding()
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isStaticText)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle())
            .frame(maxHeight: .infinity, alignment: .top)
            
            HStack {
                Button("Previous") {
                    if currentPage > 0 { currentPage -= 1 }
                }
                .disabled(currentPage == 0)
                
                Spacer()
                
                Button(currentPage < pages.count - 1 ? "Next" : "Done") {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        isPresented = false
                        SettingsManager.shared.shownIntro = true
                    }
                }
            }
            .padding([.leading, .trailing])
        }
    }
}
