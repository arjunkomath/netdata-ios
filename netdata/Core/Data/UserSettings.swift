//
//  UserSettings.swift
//  netdata
//
//  Created by Arjun Komath on 26/7/20.
//

import Foundation
import Combine
import SwiftUI

class UserSettings: ObservableObject {
    var window: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window else {
            return nil
        }
        return window
    }
    
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
    
    // MARK: - UI/UX
    
    @Published var appTintColor: Color {
        didSet {
            UserDefaults.standard.setColor(color: appTintColor, forKey: "appTintColor")
            self.window?.tintColor = UIColor(appTintColor)
        }
    }
    
    @Published var hapticFeedback: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedback, forKey: "hapticFeedback")
        }
    }
    
    init() {
        // Favourite Server
        self.favouriteServerId = UserDefaults.standard.object(forKey: "favouriteServerId") as? String ?? ""
        self.favouriteServerUrl = UserDefaults.standard.object(forKey: "favouriteServerUrl") as? String ?? ""
        
        // Appearance
        self.appTintColor = UserDefaults.standard.colorForKey(key: "appTintColor") != nil ?
            Color(UserDefaults.standard.colorForKey(key: "appTintColor")!) : Color.blue
        self.hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool ?? true
    }
}
