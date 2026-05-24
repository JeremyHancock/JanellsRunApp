import SwiftUI

struct HeaderView: View {
    var body: some View {
        Image("richmond-silhouette")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -20)
            .clipped()
    }
}
