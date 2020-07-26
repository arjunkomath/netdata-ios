//
//  AbsoluteUsageData.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

struct AbsoluteUsageData: View {
    var usage: CGFloat
    var title: String
    var showArrows: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            if showArrows {
                if usage >= 0 {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.green)
                        .imageScale(.large)
                        .frame(width: 24)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                        .imageScale(.large)
                        .frame(width: 24)
                }
            }
            
            VStack(alignment: .leading, spacing: 5){
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(0)
                    .frame(alignment: .leading)
                
                Text(String(format: "%.2f", self.usage))
                    .font(.headline)
                    .padding(0)
                
            }
        }
        .frame(width: 120, height: 50)
    }
}

struct AbsoluteUsageData_Previews: PreviewProvider {
    static var previews: some View {
        AbsoluteUsageData(usage: 4254.234235,
                          title: "system",
                          showArrows: true)
        
        AbsoluteUsageData(usage: -425.234235,
                          title: "system",
                          showArrows: true)
        
        AbsoluteUsageData(usage: 425.234235,
                          title: "system",
                          showArrows: false)
    }
}
