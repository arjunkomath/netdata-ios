//
//  netdataApp.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("AppDelegate: Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        if let token = fcmToken {
            Task {
                await UserService.shared.updateDeviceToken(token: token)
            }
        }
    }
    
}

@main
struct netdataApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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
            .environmentObject(UserService.shared)
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
