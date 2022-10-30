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
    case secondsToHours
}

struct DataGrid: View {
    var labels: [String]
    var data: [[Double?]]
    var dataType: GridDataType
    var showArrows: Bool
    
    var body: some View {
        if labels.count > 1 && self.data.count > 0 {
            LazyVGrid(columns: self.getGridColumns(), alignment: .leading, spacing: 8) {
                ForEach(Array(labels.enumerated()), id: \.offset) { i, label in
                    if (i > 0) { // First label is time, hence ignored
                        if dataType == .percentage {
                            PercentageUsageData(usage: CGFloat(self.data[0][i] ?? 0),
                                                title: label)
                        }
                        if dataType == .absolute {
                            AbsoluteUsageData(usage: CGFloat(self.data[0][i] ?? 0),
                                              title: label,
                                              showArrows: showArrows)
                        }
                        if dataType == .secondsToHours {
                            AbsoluteUsageData(usage: CGFloat(self.data[0][i] ?? 0),
                                              title: label,
                                              showArrows: showArrows,
                                              convertSecondsToHours: true)
                        }
                    }
                }
            }
        } else {
            LazyVGrid(columns: self.getGridColumns(), spacing: 8) {
                ForEach((1...2), id: \.self) { _ in
                    AbsoluteUsageData(usage: 0.1,
                                      title: "loading",
                                      showArrows: false)
                    .redacted(reason: .placeholder)
                }
            }
        }
    }
    
    func getGridColumns() -> [GridItem] {
#if targetEnvironment(macCatalyst)
        return [GridItem(.adaptive(minimum: 120))]
#else
        var columnWidth: CGFloat = self.dataType == GridDataType.percentage ? 65 : 80
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            columnWidth = 120
        }
        
        if self.showArrows {
            columnWidth = 120
        }
        
        return [GridItem(.adaptive(minimum: columnWidth))]
#endif
    }
}

struct DataGrid_Previews: PreviewProvider {
    static var previews: some View {
        DataGrid(labels: ["test", "test"],
                 data: [[5, 4]],
                 dataType: .absolute,
                 showArrows: false)
    }
}
