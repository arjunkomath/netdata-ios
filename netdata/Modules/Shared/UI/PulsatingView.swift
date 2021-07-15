//
//  PulsatingView.swift
//  netdata
//
//  Created by Arjun Komath on 13/6/21.
//

import SwiftUI
import Combine

struct PulsatingView: View {
    var live: Bool
    
    @State var animate = false
    
    var body: some View {
        VStack {
            if live {
                ZStack {
                    Circle().fill(Color.green.opacity(0.25)).frame(width: 24, height: 24).scaleEffect(self.animate ? 1 : 0)
                    Circle().fill(Color.green.opacity(0.45)).frame(width: 16, height: 16).scaleEffect(self.animate ? 1 : 0)
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        self.animate = true
                    }
                }
            } else {
                ZStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                }
                .frame(width: 24, height: 24)
            }
        }
    }
}

struct TestPulseColorView_Previews: PreviewProvider {
    static var previews: some View {
        PulsatingView(live: true)
        
        Spacer()
        
        PulsatingView(live: false)
    }
}
