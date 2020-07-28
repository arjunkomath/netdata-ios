//
//  CloudService.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import Foundation
import CloudKit

protocol PublicCloudService {
    var database: CKDatabase { get }
}

extension PublicCloudService {
    var container: CKContainer {
        CKContainer.init(identifier: "iCloud.NetData")
    }
    
    var database: CKDatabase {
        self.container.privateCloudDatabase
    }
        
    func serviceSubscriptionExist(recordType: CKRecord.RecordType, subs: [CKSubscription]?) -> CKQuerySubscription? {
        if subs == nil || subs?.isEmpty == true {
            return nil
        } else if let sub = subs?.first(where: { (sub) -> Bool in
            if let sub = sub as? CKQuerySubscription, sub.recordType == recordType {
                return true
            }
            return false
        }) {
            return sub as? CKQuerySubscription
        } else {
            return nil
        }
    }
}
