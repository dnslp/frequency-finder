import SwiftUI

struct PitchComparisonBar: View {
    var centsOffset: Double
    var toleranceCents: Double = 50  // ± range

    private var normalizedOffset: Double {
        max(-toleranceCents, min(centsOffset, toleranceCents)) / toleranceCents
    }

    private var markerColor: Color {
        let absCents = abs(centsOffset)
        switch absCents {
        case 0..<5:
            return .green
        case 5..<15:
            return .yellow
        case 15..<30:
            return .orange
        default:
            return .red
        }
    }

    private var labelText: String {
        let cents = Int(centsOffset.rounded())
        return cents > 0 ? "+\(cents)¢" : "\(cents)¢"
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let markerOffset = CGFloat(normalizedOffset) * (width / 2)

            ZStack {
                // Background line
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)

                // Tolerance zone
                Capsule()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: width * 0.4, height: 8)

                // Center reference line
                Rectangle()
                    .fill(Color.secondary)
                    .frame(width: 2, height: 20)

                // Marker + Label
                VStack(spacing: 2) {
                    Text(labelText)
                        .font(.caption2)
                        .foregroundColor(markerColor)
                        .bold()

                    Rectangle()
                        .fill(markerColor)
                        .frame(width: 4, height: 20)
                }
                .offset(x: markerOffset)
                .animation(.easeOut(duration: 0.2), value: markerOffset)
            }
        }
        .frame(height: 36)
        .padding(.horizontal)
    }
}
