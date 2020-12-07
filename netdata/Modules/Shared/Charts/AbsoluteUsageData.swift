//
//  AbsoluteUsageData.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

struct AbsoluteUsageData: View {
    var usage: CGFloat?
    var stringValue: String?
    var title: String
    var showArrows: Bool
    var convertSecondsToHours: Bool?
    
    var body: some View {
        HStack(spacing: 10) {
            if showArrows && usage != nil {
                if usage! >= 0 {
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
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(0)
                    .frame(alignment: .leading)
                
                if stringValue != nil && !stringValue!.isEmpty {
                    Text(stringValue!)
                        .font(.headline)
                        .padding(0)
                } else if usage != nil {
                    if convertSecondsToHours ?? false {
                        Text(String(format: "%.f", ((usage!/60)/60)))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .padding(0)
                    } else {
                        Text(String(format: "%.2f", usage!))
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .padding(0)
                    }
                }
            }
        }
        .frame(height: 50)
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
        AbsoluteUsageData(usage: 72822.00323,
                          title: "dhcp",
                          showArrows: false,
                          convertSecondsToHours: true)
    }
}
