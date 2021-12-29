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
    
    // MARK:- First launch
    
    @Published var HasLaunchedOnce: Bool {
        didSet {
            UserDefaults.standard.set(HasLaunchedOnce, forKey: "HasLaunchedOnce")
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
    
    @Published var enableCharts: Bool {
        didSet {
            UserDefaults.standard.set(enableCharts, forKey: "enableCharts")
        }
    }
    
    // MARK: - Charts
    
    @Published var bookmarks: [String] {
        didSet {
            NSUbiquitousKeyValueStore.default.set(bookmarks, forKey: "bookmarks")
        }
    }
    
    // MARK: - Alarms
    
    @Published var ignoredAlarms: [String] {
        didSet {
            NSUbiquitousKeyValueStore.default.set(ignoredAlarms, forKey: "ignoredAlarms")
        }
    }
    
    init() {
        // First launch
        self.HasLaunchedOnce = UserDefaults.standard.object(forKey: "HasLaunchedOnce") as? Bool ?? false
        
        // Appearance
        self.appTintColor = UserDefaults.standard.colorForKey(key: "appTintColor") != nil ?
            Color(UserDefaults.standard.colorForKey(key: "appTintColor")!) : Color.blue
        self.hapticFeedback = UserDefaults.standard.object(forKey: "hapticFeedback") as? Bool ?? true
        
        // Features
        self.enableCharts = UserDefaults.standard.object(forKey: "enableCharts") as? Bool ?? false
        
        // Charts
        self.bookmarks = NSUbiquitousKeyValueStore.default.array(forKey: "bookmarks") as? [String] ?? []
        
        // Alarms
        self.ignoredAlarms = NSUbiquitousKeyValueStore.default.array(forKey: "ignoredAlarms") as? [String] ?? []
    }
}
