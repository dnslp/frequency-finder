import SwiftUI

struct SparklineView: View {
    let data: [Double]

    var body: some View {
        Canvas { context, size in
            guard let data = normalizedData(), data.count > 1 else { return }

            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height * (1 - data[0])))

            for i in 1..<data.count {
                let x = size.width * (CGFloat(i) / CGFloat(data.count - 1))
                let y = size.height * (1 - data[i])
                path.addLine(to: CGPoint(x: x, y: y))
            }

            context.stroke(path, with: .color(.accentColor), lineWidth: 2)
        }
    }

    private func normalizedData() -> [CGFloat]? {
        guard let min = data.min(), let max = data.max(), min != max else { return nil }

        return data.map { CGFloat(($0 - min) / (max - min)) }
    }
}
