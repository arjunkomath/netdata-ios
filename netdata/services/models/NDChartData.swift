//
//  NDServerData.swift
//  netdata
//
//  Created by Arjun Komath on 19/7/20.
//

import Foundation

public struct NDChartData: Decodable {
    var labels: [String]
    var data: [[Double]]
}
