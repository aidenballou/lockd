import SwiftUI

struct SectionHeader: View {
    let title: String
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(theme.tokens.typography.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(theme.tokens.colors.textSecondary)
            Spacer()
        }
    }
}

struct MetricBadge: View {
    let label: String
    let value: String
    var success: Bool = false

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.tokens.spacing.unit / 2) {
            Text(label.uppercased())
                .font(theme.tokens.typography.caption.weight(.semibold))
                .foregroundStyle(theme.tokens.colors.textSecondary)
            Text(value)
                .font(theme.tokens.typography.metric)
                .foregroundStyle(success ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary)
        }
        .padding(theme.tokens.spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.tokens.colors.bgElevated)
        .overlay(
            RoundedRectangle(cornerRadius: theme.tokens.radius.card)
                .stroke(theme.tokens.colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.tokens.radius.card))
    }
}

struct AppCard<Content: View>: View {
    @Environment(\.appTheme) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(theme.tokens.spacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.tokens.colors.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: theme.tokens.radius.card)
                    .stroke(theme.tokens.colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.tokens.radius.card))
    }
}

struct PillLabel: View {
    let text: String
    var success: Bool = false

    @Environment(\.appTheme) private var theme

    var body: some View {
        Text(text)
            .font(theme.tokens.typography.caption.weight(.semibold))
            .foregroundStyle(success ? theme.tokens.colors.successAccent : theme.tokens.colors.textSecondary)
            .padding(.horizontal, theme.tokens.spacing.unit + 2)
            .padding(.vertical, theme.tokens.spacing.unit / 2)
            .overlay(
                Capsule()
                    .stroke(success ? theme.tokens.colors.successAccent : theme.tokens.colors.border, lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.tokens.typography.body.weight(.semibold))
            .foregroundStyle(theme.tokens.colors.bgPrimary)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(theme.tokens.colors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: theme.tokens.radius.control))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: theme.celebration.standardDuration), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.tokens.typography.bodySmall.weight(.semibold))
            .foregroundStyle(theme.tokens.colors.textPrimary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(theme.tokens.colors.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: theme.tokens.radius.control)
                    .stroke(theme.tokens.colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.tokens.radius.control))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: theme.celebration.standardDuration), value: configuration.isPressed)
    }
}

struct SuccessButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.tokens.typography.bodySmall.weight(.semibold))
            .foregroundStyle(theme.tokens.colors.bgPrimary)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(theme.tokens.colors.successAccent)
            .clipShape(RoundedRectangle(cornerRadius: theme.tokens.radius.control))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: theme.celebration.standardDuration), value: configuration.isPressed)
    }
}
