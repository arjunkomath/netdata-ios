//
//  ChartListRow.swift
//  netdata
//
//  Created by Arjun Komath on 1/8/20.
//

import SwiftUI

struct ChartListRow: View {
    var chart: ServerChart;
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(chart.name) - \(chart.family)")
                    .bold()
            }
            
            Text(chart.title)
                .font(.subheadline)
        }
        .padding(5)
    }
}

struct ChartListRow_Previews: PreviewProvider {
    static var previews: some View {
        ChartListRow(chart: ServerChart(id: "ipv4.sockstat_frag_mem",
                                        name: "ipv4.sockstat_frag_mem",
                                        type: "ipv4",
                                        family: "fragments",
                                        context: "ipv4.sockstat_frag_mem",
                                        title: "IPv4 FRAG Sockets Memory (ipv4.sockstat_frag_mem)",
                                        enabled: true))
    }
}
