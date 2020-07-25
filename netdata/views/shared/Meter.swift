//
//  Meter.swift
//  netdata
//
//  Created by Arjun Komath on 19/7/20.
//

import SwiftUI

struct Meter : View {
    @Binding var progress: CGFloat
    @Binding var title: String
    
    var body: some View {
        VStack(spacing: 20){
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 20)
                    .opacity(0.1)
                
                Circle()
                    .trim(from: 0, to: self.progress)
                    .stroke(self.getColor(), lineWidth: 20)
                    .rotationEffect(.degrees(-90))
                    .overlay(
                        Text("\(Int(self.progress * 100.0))%"))
                
            }
            .padding(10)
            .frame(height: 150)
            
            Text(title)
                .font(.headline)
            
            Spacer()
        }
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
        Meter(progress: .constant(CGFloat(0.1)), title: .constant("CPU"))
    }
}
