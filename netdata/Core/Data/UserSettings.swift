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

    // MARK: - Charts
    
    static let bookmarksDidChange = Notification.Name("UserSettings.bookmarksDidChange")

    @Published var bookmarks: [String] {
        didSet {
            guard !isReloadingBookmarks else { return }
            NSUbiquitousKeyValueStore.default.set(bookmarks, forKey: "bookmarks")
            NotificationCenter.default.post(name: Self.bookmarksDidChange, object: self)
        }
    }

    private var isReloadingBookmarks = false
    private var bookmarksObserver: AnyCancellable?

    func togglePin(_ chartID: String) {
        if bookmarks.contains(chartID) {
            bookmarks.removeAll { $0 == chartID }
        } else {
            bookmarks.insert(chartID, at: 0)
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
        
        // Charts
        self.bookmarks = NSUbiquitousKeyValueStore.default.array(forKey: "bookmarks") as? [String] ?? []
        
        // Alarms
        self.ignoredAlarms = NSUbiquitousKeyValueStore.default.array(forKey: "ignoredAlarms") as? [String] ?? []

        // Views each create their own UserSettings, so a pin made on one screen has to be
        // broadcast for the others (and other devices, via iCloud) to pick it up.
        bookmarksObserver = NotificationCenter.default.publisher(for: Self.bookmarksDidChange)
            .merge(with: NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self, (notification.object as? UserSettings) !== self else { return }
                let latest = NSUbiquitousKeyValueStore.default.array(forKey: "bookmarks") as? [String] ?? []
                guard latest != self.bookmarks else { return }
                self.isReloadingBookmarks = true
                self.bookmarks = latest
                self.isReloadingBookmarks = false
            }
    }
}
