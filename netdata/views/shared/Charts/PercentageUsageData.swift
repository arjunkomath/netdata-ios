//
//  UsageData.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

struct PercentageUsageData: View {
    @Binding var usage: CGFloat
    @Binding var title: String
    
    var body: some View {
        VStack(spacing: 5){
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(0)
                .frame(alignment: .leading)
            Text("\(Int(self.usage * 100))%")
                .font(.headline)
                .padding(0)
        }
        .frame(width: 85, height: 50)
    }
}

struct PercentageUsageData_Previews: PreviewProvider {
    static var previews: some View {
        PercentageUsageData(usage: .constant(0.5), title: .constant("system"))
    }
}
