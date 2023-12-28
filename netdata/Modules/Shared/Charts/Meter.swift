//
//  Meter.swift
//  netdata
//
//  Created by Arjun Komath on 19/7/20.
//

import SwiftUI

struct Meter : View {
    var progress: CGFloat
    
    var body: some View {
        Gauge(
            value: max(progress, 0),
            in: 0...1
        ) {
            Text("%")
        } currentValueLabel: {
            Text(String(format: "%.0f", min(self.progress, 1.0)*100.0))
                .font(.caption)
                .bold()
        }
        .gaugeStyle(.accessoryCircular)
        .tint(getColor())
        .frame(width: 100, height: 100)
    }
    
    func getColor() -> Color {
        if self.progress > 0.8 {
            return Color.red
        }
        
        if self.progress > 0.5 {
            return Color.blue
        }
        
        return Color.green
    }
}

struct Meter_Previews: PreviewProvider {
    static var previews: some View {
        Meter(progress: CGFloat(0.1))
    }
}
