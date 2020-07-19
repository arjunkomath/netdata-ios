//
//  NDServerData.swift
//  netdata
//
//  Created by Arjun Komath on 19/7/20.
//

import Foundation

public struct NDServerData {
    public let labels: [String]
    public var data: [[Double]]
    
    public init(labels: [String], data: [[Double]]) {
        self.labels = labels
        self.data = data
    }
    
    public static func placeholder() -> NDServerData {
        return NDServerData(labels: [], data: [])
    }
}
