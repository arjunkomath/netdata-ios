//
//  CloudModel.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import Foundation
import CloudKit

public protocol CloudModel {
    static var RecordType: String { get }
    var record: CKRecord? { get }
    init(withRecord record: CKRecord)
    func toRecord(owner: CKRecord?) -> CKRecord
}
