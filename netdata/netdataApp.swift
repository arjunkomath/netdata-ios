//
//  netdataApp.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

@main
struct netdataApp: App {
    @ObservedObject var userSettings = UserSettings()
    
    var window: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window else {
            return nil
        }
        return window
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ServerListView()
            }
            .navigationViewStyle(.stack)
            .environmentObject(ServerService.shared)
            .onAppear {
                self.setupAppearance()
            }
        }
    }
    
    private func setupAppearance() {
        // app tint color
        self.window?.tintColor = UIColor(userSettings.appTintColor)
    }
}
