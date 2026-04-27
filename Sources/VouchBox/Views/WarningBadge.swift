import SwiftUI

struct WarningBadge: View {
    enum Style { case thirdParty, unsigned, error }
    let style: Style
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var color: Color {
        switch style {
        case .thirdParty: return .orange
        case .unsigned: return .yellow
        case .error: return .red
        }
    }

    private var icon: String {
        switch style {
        case .thirdParty: return "exclamationmark.triangle.fill"
        case .unsigned: return "lock.open.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}
