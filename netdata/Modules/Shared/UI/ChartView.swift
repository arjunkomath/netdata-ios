import SwiftUI

struct ChartView: View {
    
    private let datas: [[Double]]
    private let maxY: Double
    private let minY: Double
    
    private let lineColors = [Color.green, Color.red, Color.blue]
    
    init(datas: [[Double]], min: Double? = 0, max: Double? = 100) {
        self.datas = datas
        maxY = max ?? 0
        minY = min ?? 100
    }
    
    var body: some View {
        VStack {
            ZStack {
                ForEach(Array(datas.enumerated()), id: \.offset) { i, data in
                    chartView(data: data, lineColor: lineColors[i])
                        .frame(height: 200)
                        .background(chartBackground)
                        .overlay(chartYAxis.padding(.horizontal, 4), alignment: .leading)
                }
            }
        }
        .font(.caption)
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView(datas: [[]], min: 0, max: 100)
    }
}

extension ChartView {
    
    private func chartView(data: [Double], lineColor: Color) -> some View {
        GeometryReader { geometry in
            Path { path in
                for index in data.indices {
                    
                    let xPosition = geometry.size.width / CGFloat(data.count) * CGFloat(index + 1)
                    
                    let yAxis = maxY - minY
                    
                    let yPosition = (1 - CGFloat((data[index] - minY) / yAxis)) * geometry.size.height
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: xPosition, y: yPosition))
                    }
                    path.addLine(to: CGPoint(x: xPosition, y: yPosition))
                    
                }
            }
            .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
    
    private var chartBackground: some View {
        VStack {
            Divider()
            Spacer()
            Divider()
            Spacer()
            Divider()
        }
    }
    
    private var chartYAxis: some View {
        VStack {
            Text(maxY.asNumberString())
            Spacer()
            Text(((maxY + minY) / 2).asNumberString())
            Spacer()
            Text(minY.asNumberString())
        }
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
