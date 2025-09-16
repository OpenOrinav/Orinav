import SwiftUI

struct BeaconMapAttributionView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legal")
                .font(.title)
                .bold()
            
            HStack(spacing: 16) {
                Image("MapboxAttribution")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 71, height: 16)
                Image("TencentMapAttribution")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 16)
            }
            
            Text("Map data [© Mapbox](https://www.mapbox.com/about/maps), [© OpenStreetMap](http://www.openstreetmap.org/about/). [Improve this map](https://apps.mapbox.com/feedback/).")
            Text("Map data [© 腾讯地图](https://lbs.qq.com/). [Improve this map](https://map.wap.qq.com/app/help/detail1.html). GS粤(2023)1171号")
        }
        .frame(maxWidth: .infinity)
        .overlay(
            Button {
                isPresented = false
            } label: {
                EmptyView()
            }
                .accessibilityLabel("Close")
                .accessibilityHint("Dismisses the legal sheet")
        )
        .padding()
    }
}
