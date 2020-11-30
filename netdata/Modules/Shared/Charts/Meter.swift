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
        VStack(spacing: 10){
            ZStack {
                Circle()
                    .stroke(lineWidth: 16.0)
                    .opacity(0.3)
                    .foregroundColor(self.getColor())
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 17.0, lineCap: .round, lineJoin: .round))
                    .foregroundColor(self.getColor())
                    .rotationEffect(Angle(degrees: 270.0))
                    //.animation(.linear) //disabing animation here fixes the ui glitch that happens on SererDetailView init
                
                Text(String(format: "%.0f %%", min(self.progress, 1.0)*100.0))
                    .font(.caption)
                    .bold()
                    .animation(nil) //fixes text clipping that happens when switching from 1 digit to 2 digits
            }
            .frame(height: 72)
        }
        .frame(width: 102, height: 102)
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
