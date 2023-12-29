//
//  SettingsView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI
import StoreKit
import FirebaseAuth
import AlertToast

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) var requestReview
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var serverService: ServerService
    @EnvironmentObject var userService: UserService
    
    @ObservedObject var userSettings = UserSettings()
    
    @State private var showPushPermissionAlert = false
    @State private var hasPushPermission = false
    @State private var alertNotifications = false
    @State private var showApiKeyCopiedToast = false
    
    private var versionNumber: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("Error", comment: "")
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? NSLocalizedString("Error", comment: "")
    }
    
    @ViewBuilder
    private func makeRow(image: String,
                         text: LocalizedStringKey,
                         link: URL? = nil,
                         color: Color? = .primary) -> some View {
        if let link = link {
            Link(destination: link) {
                Label(text, systemImage: image)
                    .foregroundColor(.accentColor)
            }
        } else {
            Label(text, systemImage: image)
                .foregroundColor(color)
        }
    }
    
    @ViewBuilder
    private func makeDetailRow(image: String,
                               text: LocalizedStringKey,
                               detail: String,
                               color: Color? = .primary) -> some View {
        HStack {
            Label(text, systemImage: image)
                .foregroundColor(color)
            
            Spacer()
            Text(detail)
                .foregroundColor(.gray)
                .font(.callout)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Experience")) {
                    ColorPicker(selection: $userSettings.appTintColor, supportsOpacity: false) {
                        Label("App Tint", systemImage: "paintbrush")
                    }
#if targetEnvironment(macCatalyst)
#else
                    Toggle(isOn: $userSettings.hapticFeedback) {
                        Label("Haptic Feedback", systemImage: "waveform.path")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
#endif
                }
                
                if userService.userData != nil {
                    Section(header: Text("Alert Notifications (beta)"),
                            footer: Text("Get instant push notifications for alerts from your Netdata instance. Requires access to the terminal where Netdata Agent is running to configure custom notifications.")) {
                        Toggle(isOn: $alertNotifications) {
                            Label("Enable alerts", systemImage: "bell")
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .onChange(of: alertNotifications) { enabled in
                            Task {
                                do {
                                    if enabled && !hasPushPermission {
                                        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
                                        let result = try await UNUserNotificationCenter.current().requestAuthorization(
                                            options: authOptions
                                        )
                                        
                                        if (!result) {
                                            alertNotifications = false
                                            showPushPermissionAlert = true
                                        }
                                    }
                                    
                                    await userService.toggleAlerts(enabled: enabled)
                                } catch {
                                    print("Failed to fetch push permission", error)
                                }
                            }
                        }
                        .onChange(of: scenePhase) { newScenePhase in
                            switch newScenePhase {
                            case .active:
                                print("App is in the foreground")
                                Task {
                                    let settings = await UNUserNotificationCenter.current().notificationSettings()
                                    hasPushPermission = settings.authorizationStatus == .authorized
                                }
                            case .inactive:
                                print("App is inactive")
                            case .background:
                                print("App is in the background")
                            @unknown default:
                                print("Unknown scene phase")
                            }
                        }
                        
                        if alertNotifications {
                            Button(action: {
                                UIPasteboard.general.string = userService.userData?.api_key
                                showApiKeyCopiedToast = true
                            }) {
                                Label("Copy API key", systemImage: "doc.on.doc")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        makeRow(image: "server.rack", text: "View configuration guide",
                                link: URL(string: "https://github.com/arjunkomath/netdata-ios/blob/main/docs/alert-notifications.md")!)
                    }
                }
                
                if userSettings.bookmarks.count > 0 {
                    Section(header: Text("Pinned charts")) {
                        ForEach(userSettings.bookmarks, id: \.self) { chart in
                            Label(chart, systemImage: "pin")
                        }
                        .onDelete(perform: deleteBookmarks)
                    }
                }
                
                if userSettings.ignoredAlarms.count > 0 {
                    Section(header: Text("Hidden alarms")) {
                        ForEach(userSettings.ignoredAlarms, id: \.self) { alarm in
                            Label(alarm, systemImage: "alarm")
                        }
                        .onDelete(perform: deleteIgnoredAlarms)
                    }
                }
                
                Section(header: Text("Data")) {
                    makeRow(image: self.serverService.isCloudEnabled ? "icloud.fill" : "icloud.slash",
                            text: "iCloud Sync \(self.serverService.isCloudEnabled ? "Active" : "Failed")",
                            color: self.serverService.isCloudEnabled ? .green : .red)
                    makeRow(image: "server.rack",
                            text: "DB Sync \(Auth.auth().currentUser != nil ? "Active" : "Failed")",
                            color: Auth.auth().currentUser != nil ? .green : .red)
                }
                
                Section(
                    header: Text("About"),
                    footer: Text("Please note that this app is an independent iOS/macOS client and is not officially affiliated with, authorized, maintained, sponsored, or endorsed by Netdata (Netdata Inc) or any of its affiliates or subsidiaries. This application is an open-source, and it operates by utilizing the APIs provided by Netdata.")
                ) {
                    makeRow(image: "desktopcomputer", text: "Source code",
                            link: URL(string: "https://github.com/arjunkomath/netdata-ios")!)
                    makeRow(image: "ant", text: "Report an issue",
                            link: URL(string: "https://github.com/arjunkomath/netdata-ios/issues")!)
                    
                    Button(action: {
                        requestReview()
                    }) {
                        Label("Write a review", systemImage: "square.and.pencil")
                            .foregroundColor(.accentColor)
                    }
                    
                    makeDetailRow(image: "tag",
                                  text: "App version",
                                  detail: "\(versionNumber) (\(buildNumber))")
                }
            }
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                hasPushPermission = settings.authorizationStatus == .authorized
                alertNotifications = hasPushPermission && (userService.userData?.enable_alert_notifications ?? false)
            }
            .listStyle(.sidebar)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    dismissButton
                }
            }
            .toast(isPresenting: $showApiKeyCopiedToast) {
                AlertToast(
                    displayMode: .banner(.pop),
                    type: .complete(.green),
                    title: "API key copied to clipboard"
                )
            }
            .alert(isPresented: $showPushPermissionAlert) {
                Alert(title: Text("Enable push notifications"),
                      message: Text("You will receive instant push notifications for alerts from your Netdata instance."),
                      primaryButton: .default(Text("Open Settings")) {
                    Task {
                        await UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                },
                      secondaryButton: .cancel())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var dismissButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.small)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .accentColor(Color.red)
    }
    
    private func deleteBookmarks(at offsets: IndexSet) {
        userSettings.bookmarks.remove(atOffsets: offsets)
    }
    
    private func deleteIgnoredAlarms(at offsets: IndexSet) {
        userSettings.ignoredAlarms.remove(atOffsets: offsets)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
