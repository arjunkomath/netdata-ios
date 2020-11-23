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
                ForEach(1..<self.labels.count) { i in
                    if self.dataType == .percentage {
                        PercentageUsageData(usage: CGFloat(self.data.first![i] ?? 0),
                                            title: self.labels[i])
                    }
                    if self.dataType == .absolute {
                        AbsoluteUsageData(usage: CGFloat(self.data.first![i] ?? 0),
                                          title: self.labels[i],
                                          showArrows: self.showArrows)
                    }
                    if self.dataType == .secondsToHours {
                        AbsoluteUsageData(usage: CGFloat(self.data.first![i] ?? 0),
                                          title: self.labels[i],
                                          showArrows: self.showArrows,
                                          convertSecondsToHours: true)
                    }
                }
            }
            .animation(nil)
        } else {
            LazyVGrid(columns: self.getGridColumns(), spacing: 8) {
                ForEach((1...4), id: \.self) { _ in
                    AbsoluteUsageData(usage: 0.1,
                                      title: "loading",
                                      showArrows: false)
                        .redacted(reason: .placeholder)
                }
            }
            .animation(nil)
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
