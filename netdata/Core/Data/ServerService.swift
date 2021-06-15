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
import os.log

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
    
    public func refresh() async {
        await fetchServers()
        
        WidgetCenter.shared.reloadAllTimelines()
        
        do {
            let status = try await container.accountStatus()
            self.isCloudEnabled = status == .available
        } catch {
            self.setError(error: error)
        }
    }
    
    public func add(server: NDServer) async {
        self.isSynching = true
        
        let record = server.toRecord(owner: nil)
        var server = server
        
        do {
            let record = try await database.save(record)
            
            server.record = record
            self.defaultServers.insert(server, at: 0)
            self.isSynching = false
        } catch {
            self.isSynching = false
            self.setError(error: error)
        }
    }
    
    public func edit(server: NDServer) {
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
            async {
                switch result {
                case .success():
                    if fetch {
                        await self.fetchServers()
                    }
                    
                case .failure(let error):
                    self.setError(error: error)
                }
            }
        }
        
        database.add(operation)
    }
    
    @MainActor
    @discardableResult
    func fetchServers() async -> ([NDServer], [NDServer]) {
        self.isSynching = true
        
        do {
            let query = CKQuery(recordType: NDServer.RecordType, predicate: NSPredicate(value: true))
            let (matchResults, _) = try await database.records(matching: query, inZoneWith: nil)
            
            let nativeRecords: [NDServer] = matchResults
                .compactMap { _, result in try? NDServer(withRecord: result.get()) }
            
            self.favouriteServers = nativeRecords.filter { $0.isFavourite == 1 }
            self.defaultServers = nativeRecords.filter { $0.isFavourite != 1 }
            self.isSynching = false

            return (self.favouriteServers, self.defaultServers)
        } catch {
            self.favouriteServers = []
            self.defaultServers = []
            self.setError(error: error)
            self.isSynching = false
            return ([],[])
        }
    }
    
    private func setError(error: Error?) {
        if error != nil {
            self.reportError(error!)
        }
        
        DispatchQueue.main.async {
            self.mostRecentError = error
        }
    }
    
    private func reportError(_ error: Error) {
        guard let ckerror = error as? CKError else {
            os_log("Not a CKError: \(error.localizedDescription)")
            return
        }
        
        switch ckerror.code {
        case .partialFailure:
            // Iterate through error(s) in partial failure and report each one.
            let dict = ckerror.userInfo[CKPartialErrorsByItemIDKey] as? [NSObject: CKError]
            if let errorDictionary = dict {
                for (_, error) in errorDictionary {
                    reportError(error)
                }
            }
            
            // This switch could explicitly handle as many specific errors as needed, for example:
        case .unknownItem:
            os_log("CKError: Record not found.")
            
        case .notAuthenticated:
            os_log("CKError: An iCloud account must be signed in on device or Simulator to write to a PrivateDB.")
            
        case .permissionFailure:
            os_log("CKError: An iCloud account permission failure occured.")
            
        case .networkUnavailable:
            os_log("CKError: The network is unavailable.")
            
        default:
            os_log("CKError: \(error.localizedDescription)")
        }
    }
}
