//
//  DataGrid.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

enum GridDataType {
    case percentage
    case absolute
}

struct DataGrid: View {
    @Binding var labels: [String]
    @Binding var data: [[Double]]
    @Binding var dataType: GridDataType
    @Binding var showArrows: Bool
    
    var body: some View {
        if labels.count > 1 {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: self.dataType == GridDataType.percentage ? 65 : 80))], spacing: 10) {
                ForEach(1..<self.labels.count) { i in
                    if self.dataType == .percentage {
                        PercentageUsageData(usage: .constant(CGFloat(self.data.first![i])),
                                            title: self.$labels[i])
                    }
                    if self.dataType == .absolute {
                        AbsoluteUsageData(usage: .constant(CGFloat(self.data.first![i])),
                                          title: self.$labels[i],
                                          showArrows: self.$showArrows)
                    }
                }
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                ForEach((1...4), id: \.self) { _ in
                    AbsoluteUsageData(usage: .constant(0.1),
                                      title: .constant("loading"),
                                      showArrows: .constant(false))
                        .redacted(reason: .placeholder)
                }
            }
        }
    }
}

struct DataGrid_Previews: PreviewProvider {
    static var previews: some View {
        DataGrid(labels: .constant(["test", "test"]),
                 data: .constant([[5, 4]]),
                 dataType: .constant(.absolute),
                 showArrows: .constant(false))
    }
}
