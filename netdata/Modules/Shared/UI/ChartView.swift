import SwiftUI
import Charts

struct ChartDataPoint: Identifiable {
    let id = UUID()
    var label: String
    var value: Double
    var time: String
}

struct ChartView: View {
    var data: ServerData
    
    var body: some View {
        let chartData = prepareChartData(serverData: data)
        
        Chart {
            ForEach(chartData) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.time),
                    y: .value(dataPoint.label, dataPoint.value)
                )
                .foregroundStyle(by: .value("Label", dataPoint.label))
                .interpolationMethod(.catmullRom)
            }
        }
    }
    
    func prepareChartData(serverData: ServerData) -> [ChartDataPoint] {
        var chartData: [ChartDataPoint] = []
        
        for dataIndex in 0..<serverData.data.count {
            let time = serverData.data[dataIndex][0] ?? 0.0
            for labelIndex in 1..<serverData.labels.count {
                let label = serverData.labels[labelIndex]
                if let value = serverData.data[dataIndex][labelIndex] {
                    chartData.append(
                        ChartDataPoint(
                            label: label,
                            value: value,
                            time: Date(timeIntervalSince1970: time)
                                .formatted(.dateTime.minute().second())
                        )
                    )
                }
            }
        }
        
        return chartData.reversed()
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(data: ServerData(labels: [], data: []))
    }
}

extension Double {
    
    /// Converts a Double into string representation
    /// ```
    /// Convert 1.2345 to "1.23"
    /// ```
    func asNumberString() -> String {
        return String(format: "%.2f", self)
    }
    
    /// Converts a Double into string representation with percent symbol
    /// ```
    /// Convert 1.2345 to "1.23%"
    /// ```
    func asPercentString() -> String {
        return asNumberString() + "%"
    }
    
}
