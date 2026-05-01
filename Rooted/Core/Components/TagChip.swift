import SwiftUI

struct TagChip: View {
    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
            }

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppTheme.Colors.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.Colors.chipBackground)
        .clipShape(Capsule())
    }
}

struct SelectableTagChip: View {
    let title: String
    var isSelected: Bool
    var icon: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                }

                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(isSelected ? Color.white : AppTheme.Colors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.Colors.highlight : AppTheme.Colors.chipBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
