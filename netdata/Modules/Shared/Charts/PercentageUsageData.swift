//
//  UsageData.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

struct PercentageUsageData: View {
    var usage: CGFloat
    var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5){
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.gray)
                .padding(0)
                .frame(alignment: .leading)
            
            Text("\(Int(self.usage))%")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .padding(0)
        }
        .frame(height: 50)
    }
}

struct PercentageUsageData_Previews: PreviewProvider {
    static var previews: some View {
        PercentageUsageData(usage: 0.5, title: "system")
    }
}
