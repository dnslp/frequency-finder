//
//  SineWaveView.swift
//  FrequencyFinder
//
//  Created by David Nyman on 7/28/25.
//


import SwiftUI

struct SineWaveView: View {
    var frequency: Double   // Hz
    var amplitude: Double   // 0.0 to 1.0
    var phase: Double       // animation driver
    var height: CGFloat = 60

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let width = size.width
            let step = width / 100  // control smoothness

            for x in stride(from: 0, through: width, by: step) {
                let relativeX = x / width
                let radians = 2 * .pi * frequency * relativeX + phase
                let y = sin(radians) * amplitude * height / 2 + height / 2
                if x == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(.accentColor), lineWidth: 2)
        }
        .frame(height: height)
        .clipped()
    }
}
