//
//  NDServerInfo.swift
//  netdata
//
//  Created by Arjun Komath on 18/7/20.
//

import Foundation

public struct NDServerInfo {
    public let osName: String
    public let osVersion: String
    public let kernelName: String
    public let architecture: String
    
    public init(osName: String, osVersion: String, kernelName: String, architecture: String) {
        self.osName = osName
        self.osVersion = osVersion
        self.kernelName = kernelName
        self.architecture = architecture
    }
    
    public static func placeholder() -> NDServerInfo {
        return NDServerInfo(osName: "", osVersion: "", kernelName: "", architecture: "")
    }
}
