import SwiftUI

struct UsageGaugeView: View {
    let label: String
    let percentage: Int
    let timeRemaining: String?
    let warningThreshold: Double
    let criticalThreshold: Double

    private var gaugeColor: Color {
        ColorThreshold.usageColor(for: percentage, warning: warningThreshold, critical: criticalThreshold)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: CGFloat(min(percentage, 100)) / 100)
                    .stroke(
                        gaugeColor.gradient,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6), value: percentage)
                    .shadow(color: gaugeColor.opacity(0.5), radius: 6, x: 0, y: 0)
                VStack(spacing: 2) {
                    Text("\(percentage)%")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.3), value: percentage)
                    if let t = timeRemaining {
                        Text(t)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 136, height: 136)

            VStack(spacing: 3) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                if let t = timeRemaining {
                    Text("resets in \(t)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
    }
}
