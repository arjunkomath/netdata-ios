//
//  netdataApp.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import Firebase

@main
struct netdataApp: App {
    @ObservedObject var userSettings = UserSettings()
    
    init() {
        //FirebaseApp.configure()
    }
    
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
            ServerListView()
                .environmentObject(ServerService.shared)
                .onAppear {
                    self.setupAppearance()
                }
        }
    }
    
    private func setupAppearance() {
        // app tint color
        self.window?.tintColor = UIColor(userSettings.appTintColor)
        
        // rounded title font
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withSymbolicTraits(.traitBold)?
            .withDesign(UIFontDescriptor.SystemDesign.rounded)
        
        UINavigationBar.appearance().largeTitleTextAttributes = [
            NSAttributedString.Key.font:UIFont.init(descriptor: descriptor!, size: 34)
        ]
    }
}
