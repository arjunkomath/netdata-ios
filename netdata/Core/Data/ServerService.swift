//
//  ServerService.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import Foundation
import CloudKit
import WidgetKit

public class ServerService: ObservableObject, PublicCloudService {
    
    // MARK: - Vars
    public static let shared = ServerService()
    public static var userCloudKitId: CKRecord.ID?
    
    @Published public var servers: [NDServer] = []
    @Published public var mostRecentError: Error?
    @Published public var isSynching = true
    @Published public var isCloudEnabled = true
    
    init() {
        container.accountStatus { (status, error) in
            DispatchQueue.main.async {
                self.isCloudEnabled = status == .available
            }
        }
        
        container.fetchUserRecordID { (id, error) in
            Self.userCloudKitId = id
        }
    }
    
    public func refresh() {
        fetchServers()
        
        WidgetCenter.shared.reloadAllTimelines()
        
        container.accountStatus { (status, error) in
            DispatchQueue.main.async {
                self.isCloudEnabled = status == .available
            }
        }
    }
    
    public func add(server: NDServer) {
        self.isSynching = true
        
        let record = server.toRecord(owner: nil)
        var server = server
        database.save(record) { (record, error) in
            DispatchQueue.main.async {
                if let record = record {
                    server.record = record
                    self.servers.insert(server, at: 0)
                }
                
                self.isSynching = false
                self.setError(error: error)
            }
        }
    }
    
    public func edit(server: NDServer) {
        isSynching = true
        let operation = CKModifyRecordsOperation(recordsToSave: [server.toRecord(owner: nil)],
                                                 recordIDsToDelete: nil)
        addOperation(operation: operation, fetch: true)
    }
    
    public func delete(server: NDServer) {
        servers.removeAll(where: { server.id == $0.id })
        if let record = server.record {
            let operation = CKModifyRecordsOperation(recordsToSave: nil,
                                                     recordIDsToDelete: [record.recordID])
            addOperation(operation: operation, fetch: false)
        }
    }
    
    private func addOperation(operation: CKModifyRecordsOperation, fetch: Bool) {
        operation.modifyRecordsCompletionBlock = { _, _, error in
            DispatchQueue.main.async {
                self.setError(error: error)
                if fetch {
                    self.fetchServers()
                }
            }
        }
        database.add(operation)
    }
    
    private func fetchServers() {
        self.isSynching = true
        let query = CKQuery(recordType: NDServer.RecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { (records, error) in
            self.setError(error: error)
            if let records = records {
                var nativeRecords: [NDServer] = []
                for record in records {
                    nativeRecords.append(NDServer(withRecord: record))
                }
                DispatchQueue.main.async {
                    self.servers = nativeRecords
                }
            } else {
                self.servers = []
            }
            DispatchQueue.main.async {
                self.isSynching = false
            }
        }
    }
    
    private func setError(error: Error?) {
        if error != nil {
            print(error!)
        }
        
        DispatchQueue.main.async {
            self.mostRecentError = error
        }
    }
}
