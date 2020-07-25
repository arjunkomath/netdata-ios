//
//  AbsoluteUsageData.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

struct AbsoluteUsageData: View {
    @Binding var usage: CGFloat
    @Binding var title: String
    
    var body: some View {
        VStack(spacing: 5){
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(0)
                .frame(alignment: .leading)
            Text("\(Int(self.usage))")
                .font(.headline)
                .padding(0)
        }
        .frame(width: 75, height: 50)
    }
}

struct AbsoluteUsageData_Previews: PreviewProvider {
    static var previews: some View {
        AbsoluteUsageData(usage: .constant(425), title: .constant("system"))
    }
}
