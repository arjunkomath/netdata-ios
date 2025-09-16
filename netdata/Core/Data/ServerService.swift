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

@MainActor
class ServerService: ObservableObject, PublicCloudService {
    public static let shared = ServerService()
    
    @Published public var favouriteServers: [NDServer] = []
    @Published public var defaultServers: [NDServer] = []
    @Published public var mostRecentError: Error?
    @Published public var isSynching = true
    @Published public var isCloudEnabled = true
    @Published public var showingDeleteConfirmation = false
    @Published public var serverToDelete: NDServer?
    
    init() {
        container.accountStatus { (status, error) in
            DispatchQueue.main.async {
                self.isCloudEnabled = status == .available
            }
        }
    }
    
    public func refresh() async {
        await fetchServers()
        
        WidgetCenter.shared.reloadAllTimelines()
        
        do {
            let status = try await container.accountStatus()
            DispatchQueue.main.async {
                self.isCloudEnabled = status == .available
            }
            self.setError(error: nil)
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
    
    public func requestDelete(server: NDServer) {
        serverToDelete = server
        showingDeleteConfirmation = true
    }
    
    public func confirmDelete() async {
        guard let server = serverToDelete else { return }
        
        showingDeleteConfirmation = false
        await performDelete(server: server)
        serverToDelete = nil
    }
    
    public func cancelDelete() {
        showingDeleteConfirmation = false
        serverToDelete = nil
    }
    
    private func performDelete(server: NDServer) async {
        self.isSynching = true
        
        // Remove from local arrays first
        defaultServers.removeAll(where: { server.id == $0.id })
        favouriteServers.removeAll(where: { server.id == $0.id })
        
        // Delete from CloudKit if it has a record
        if let record = server.record {
            do {
                try await database.deleteRecord(withID: record.recordID)
                os_log("Successfully deleted server: \(server.name ?? "Unknown")")
                self.isSynching = false
                serverToDelete = nil
            } catch {
                os_log(.error, "Failed to delete server: \(server.name ?? "Unknown") - \(error.localizedDescription)")
                // Re-add the server back to the appropriate list since deletion failed
                if server.isFavourite == 1 {
                    favouriteServers.insert(server, at: 0)
                } else {
                    defaultServers.insert(server, at: 0)
                }
                self.setError(error: error)
                self.isSynching = false
            }
        } else {
            self.isSynching = false
            serverToDelete = nil
        }
    }
    
    private func addOperation(operation: CKModifyRecordsOperation, fetch: Bool) {
        operation.modifyRecordsResultBlock = { result in
            Task {
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
            query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
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
        if let error = error {
            self.reportError(error)
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
