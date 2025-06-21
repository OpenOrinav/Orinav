import SwiftUI

struct BeaconIntroView: View {
    @State var currentPage = 0
    @Binding var isPresented: Bool
    
    private let pages: [LocalizedStringKey] = [
        "intro_page1_title",
        "intro_page2_title",
        "intro_page3_title",
        "intro_page4_title",
        "intro_page5_title"
    ]
    private let contents: [LocalizedStringKey] = [
        "intro_page1_content",
        "intro_page2_content",
        "intro_page3_content",
        "intro_page4_content",
        "intro_page5_content"
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
