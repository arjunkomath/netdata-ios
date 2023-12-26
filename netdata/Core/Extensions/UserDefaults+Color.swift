//
//  UserDefaults+Color.swift
//  netdata
//
//  Created by Arjun Komath on 29/7/20.
//

import Foundation
import SwiftUI

extension UserDefaults {
    func colorForKey(key: String) -> UIColor? {
        var colorReturned: UIColor?
        if let colorData = data(forKey: key) {
            do {
                colorReturned = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData)
            } catch {
                print("Error UserDefaults:", error)
            }
        }
        return colorReturned
    }
    
    
    func setColor(color: Color?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) as NSData?
                colorData = data
            } catch {
                print("Error UserDefaults")
            }
        }
        set(colorData, forKey: key)
    }
}
