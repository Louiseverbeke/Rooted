import SwiftUI
import UIKit

struct PersonAvatarView: View {
    let name: String
    let profileImageDataBase64: String?
    let size: CGFloat

    var body: some View {
        Group {
            if
                let profileImageDataBase64,
                let data = Data(base64Encoded: profileImageDataBase64),
                let uiImage = UIImage(data: data)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.highlight, AppTheme.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        Text(initials)
                            .font(.system(size: size * 0.34, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}
