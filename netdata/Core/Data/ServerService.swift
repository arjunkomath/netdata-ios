//
//  ServerService.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import Foundation
import CloudKit
import Combine
import WidgetKit

public class ServerService: ObservableObject, PublicCloudService {
    
    public static var cancellable = Set<AnyCancellable>()
    
    // MARK: - Vars
    public static let shared = ServerService()
    public static var userCloudKitId: CKRecord.ID?
    
    @Published public var favouriteServers: [NDServer] = []
    @Published public var defaultServers: [NDServer] = []
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
            if (id != nil) {
                Self.userCloudKitId = id
            }
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
                    self.defaultServers.insert(server, at: 0)
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
        defaultServers.removeAll(where: { server.id == $0.id })
        favouriteServers.removeAll(where: { server.id == $0.id })
        
        if let record = server.record {
            let operation = CKModifyRecordsOperation(recordsToSave: nil,
                                                     recordIDsToDelete: [record.recordID])
            addOperation(operation: operation, fetch: false)
        }
    }
    
    private func addOperation(operation: CKModifyRecordsOperation, fetch: Bool) {
        operation.modifyRecordsResultBlock = { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    if fetch {
                        self.fetchServers()
                    }
                    
                case .failure(let error):
                    self.setError(error: error)
                }
            }
        }
        
        database.add(operation)
    }
    
    private func fetchServers() {
        self.isSynching = true
        let query = CKQuery(recordType: NDServer.RecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.fetch(withQuery: query, inZoneWith: nil) { result in
            switch result {
            case .success(let response):
                var nativeRecords: [NDServer] = []
                
                for recordResult in response.matchResults {
                    switch recordResult.value {
                    case .success(let record):
                        nativeRecords.append(NDServer(withRecord: record))
                    case .failure(let error):
                        debugPrint("failed to parse record", error)
                    }
                }

                DispatchQueue.main.async {
                    self.favouriteServers = nativeRecords.filter { $0.isFavourite == 1 }
                    self.defaultServers = nativeRecords.filter { $0.isFavourite != 1 }
                }
                
            case .failure(let error):
                self.favouriteServers = []
                self.defaultServers = []
                self.setError(error: error)
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
