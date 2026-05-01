import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("BrandMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Rooted")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.88))

                    Text("Find your people abroad")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black.opacity(0.55))
                }

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 48)
        }
    }
}

#Preview {
    LaunchScreenView()
}
