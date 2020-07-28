//
//  ServerModel.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import Foundation
import CloudKit

public struct NDServer: CloudModel, Equatable, Identifiable {
    public static var RecordType = "NDServer"
    
    public let id: String
    public let name: String
    public let description: String
    public let url: String
    public let serverInfoJson: String
    
    public var record: CKRecord?
    public let serverInfo: ServerInfo?
    
    public var creationDate: Date {
        record?.creationDate ?? Date()
    }
    
    enum RecordKeys: String {
        case id, name, description, url, serverInfoJson
    }
    
    public static func == (lhs: NDServer, rhs: NDServer) -> Bool {
        lhs.id == rhs.id
    }
    
    public init(name: String, description: String, url: String, serverInfo: ServerInfo?) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.url = url
        self.serverInfo = serverInfo
        
        if (serverInfo != nil) {
            let jsonEncoder = JSONEncoder()
            let jsonData = try? jsonEncoder.encode(serverInfo)
            self.serverInfoJson = String(data: jsonData!, encoding: String.Encoding.utf8)!
        } else {
            self.serverInfoJson = ""
        }
    }
    
    public init(withRecord record: CKRecord) {
        self.id = record[RecordKeys.id.rawValue] as? String ?? ""
        self.name = record[RecordKeys.name.rawValue] as? String ?? ""
        self.description = record[RecordKeys.description.rawValue] as? String ?? ""
        self.url = record[RecordKeys.url.rawValue] as? String ?? ""
        self.serverInfoJson = record[RecordKeys.serverInfoJson.rawValue] as? String ?? ""
        
        self.record = record
        self.serverInfo = !self.serverInfoJson.isEmpty ?
            try! JSONDecoder().decode(ServerInfo.self, from: self.serverInfoJson.data(using: .utf8)!) : nil
    }
    
    public func toRecord(owner: CKRecord?) -> CKRecord {
        let record = self.record ?? CKRecord(recordType: Self.RecordType)
        record[RecordKeys.id.rawValue] = id
        record[RecordKeys.name.rawValue] = name
        record[RecordKeys.description.rawValue] = description
        record[RecordKeys.url.rawValue] = url
        record[RecordKeys.serverInfoJson.rawValue] = serverInfoJson
        return record
    }
}
