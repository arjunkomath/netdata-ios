//
//  SettingsView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var serverService: ServerService
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var userSettings = UserSettings()
    
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
                    
                    Toggle(isOn: $userSettings.hapticFeedback) {
                        Label("Haptic feedback", systemImage: "waveform.path")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
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
                            text: "iCloud sync \(self.serverService.isCloudEnabled ? "enabled" : "disabled")",
                            color: self.serverService.isCloudEnabled ? .green : .red)
                }
                
                Section(header: Text("About")) {
                    makeRow(image: "desktopcomputer", text: "Source code",
                            link: URL(string: "https://github.com/arjunkomath/netdata-ios")!)
                    makeRow(image: "ant", text: "Report an issue",
                            link: URL(string: "https://github.com/arjunkomath/netdata-ios/issues")!)
                    makeDetailRow(image: "tag",
                                  text: "App version",
                                  detail: "\(versionNumber) (\(buildNumber))")
                }
            }
            .listStyle(.sidebar)
            .navigationBarItems(leading: dismissButton)
            .navigationBarTitle(Text("Settings"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var dismissButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
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
