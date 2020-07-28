//
//  UserSettings.swift
//  netdata
//
//  Created by Arjun Komath on 26/7/20.
//

import Foundation
import Combine

class UserSettings: ObservableObject {
    @Published var favouriteServerId: String {
        didSet {
            UserDefaults.standard.set(favouriteServerId, forKey: "favouriteServerId")
        }
    }
    
    @Published var favouriteServerUrl: String {
        didSet {
            UserDefaults.standard.set(favouriteServerUrl, forKey: "favouriteServerUrl")
        }
    }
    
    init() {
        // Favourite Server
        self.favouriteServerId = UserDefaults.standard.object(forKey: "favouriteServerId") as? String ?? ""
        self.favouriteServerUrl = UserDefaults.standard.object(forKey: "favouriteServerUrl") as? String ?? ""
    }
}
