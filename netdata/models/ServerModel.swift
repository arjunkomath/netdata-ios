//
//  ServerModel.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import Foundation
import CloudKit

public struct Server: CloudModel, Equatable, Identifiable {
    public static var RecordType = "NDServer"
    
    public let id: String
    public let name: String
    public let description: String
    public let url: String

    public var record: CKRecord?
    
    public var creationDate: Date {
        record?.creationDate ?? Date()
    }
    
    enum RecordKeys: String {
        case id, name, description, url
    }
    
    public init(name: String, description: String, url: String) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.url = url
    }
    
    public init(withRecord record: CKRecord) {
        self.id = record[RecordKeys.id.rawValue] as? String ?? ""
        self.name = record[RecordKeys.name.rawValue] as? String ?? ""
        self.description = record[RecordKeys.description.rawValue] as? String ?? ""
        self.url = record[RecordKeys.url.rawValue] as? String ?? ""
        self.record = record
    }
    
    public func toRecord(owner: CKRecord?) -> CKRecord {
        let record = self.record ?? CKRecord(recordType: Self.RecordType)
        record[RecordKeys.id.rawValue] = id
        record[RecordKeys.name.rawValue] = name
        record[RecordKeys.description.rawValue] = description
        record[RecordKeys.url.rawValue] = url
        return record
    }
}
