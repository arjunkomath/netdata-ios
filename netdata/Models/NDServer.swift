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
    public let isFavourite: Int
    
    // authentication
    public let basicAuthBase64: String
    
    public var record: CKRecord?
    public let serverInfo: ServerInfo?
    
    public var creationDate: Date {
        record?.creationDate ?? Date()
    }
    
    enum RecordKeys: String {
        case id, name, description, url, serverInfoJson, isFavourite, basicAuthBase64
    }
    
    public static func == (lhs: NDServer, rhs: NDServer) -> Bool {
        lhs.id == rhs.id
    }
    
    public init(name: String, description: String, url: String, serverInfo: ServerInfo?, basicAuthBase64: String?, isFavourite: Int?) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.url = url
        self.serverInfo = serverInfo
        self.basicAuthBase64 = basicAuthBase64 == nil ? "" : basicAuthBase64!
        self.isFavourite = isFavourite == nil ? 0 : isFavourite!
        
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
        self.basicAuthBase64 = record[RecordKeys.basicAuthBase64.rawValue] as? String ?? ""
        self.isFavourite = record[RecordKeys.isFavourite.rawValue] as? Int ?? 0
        
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
        record[RecordKeys.basicAuthBase64.rawValue] = basicAuthBase64
        record[RecordKeys.isFavourite.rawValue] = isFavourite
        return record
    }
}

extension NDServer {
    static func placeholder() -> NDServer {
        let mockRecord = CKRecord(recordType: "MockRecord")
        mockRecord[RecordKeys.id.rawValue] = "mockId"
        mockRecord[RecordKeys.name.rawValue] = "mockName"
        mockRecord[RecordKeys.description.rawValue] = "mockDescription"
        mockRecord[RecordKeys.url.rawValue] = "mockUrl"
        mockRecord[RecordKeys.serverInfoJson.rawValue] = nil
        mockRecord[RecordKeys.basicAuthBase64.rawValue] = "mockAuth"
        mockRecord[RecordKeys.isFavourite.rawValue] = 0
        
        return NDServer(withRecord: mockRecord)
    }
}
