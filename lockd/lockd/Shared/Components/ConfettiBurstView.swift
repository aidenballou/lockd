import SwiftUI

struct ConfettiBurstView: View {
    @Environment(\.appTheme) private var theme
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<18, id: \.self) { index in
                    let angle = Double(index) / 18.0 * Double.pi * 2
                    let xOffset = CGFloat(cos(angle) * (animate ? 90 : 2))
                    let yOffset = CGFloat(sin(angle) * (animate ? 90 : 2))
                    let color: Color = index % 5 == 0 ? theme.tokens.colors.successAccent : theme.tokens.colors.textPrimary.opacity(0.6)

                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .offset(x: xOffset, y: yOffset)
                        .opacity(animate ? 0 : 1)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onAppear {
                withAnimation(.spring(duration: theme.celebration.springDuration, bounce: theme.celebration.lowBounce)) {
                    animate = true
                }
            }
        }
        .allowsHitTesting(false)
    }
}
