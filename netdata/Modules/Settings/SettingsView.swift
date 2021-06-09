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
    
    private func makeRow(image: String,
                         text: LocalizedStringKey,
                         link: URL? = nil,
                         color: Color? = .accentColor) -> some View {
        HStack {
            Image(systemName: image)
                .imageScale(.medium)
                .foregroundColor(color)
                .frame(width: 24)
            Group {
                if let link = link {
                    Link(text, destination: link)
                } else {
                    Text(text)
                }
            }
            .font(.body)
            
            Spacer()
        }
    }
    
    private func makeDetailRow(image: String,
                               text: LocalizedStringKey,
                               detail: String,
                               color: Color? = .accentColor) -> some View {
        HStack {
            Image(systemName: image)
                .imageScale(.medium)
                .foregroundColor(color)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
            Text(detail)
                .foregroundColor(.gray)
                .font(.callout)
        }
    }
    
    private func makeContentRow(image: String,
                                color: Color? = .accentColor,
                                content: AnyView) -> some View {
        HStack {
            Image(systemName: image)
                .imageScale(.medium)
                .foregroundColor(color)
                .frame(width: 24)
            Spacer()
            content
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Experience")) {
                    makeContentRow(image: "paintbrush",
                                   content: AnyView(ColorPicker("App Tint", selection: $userSettings.appTintColor, supportsOpacity: false)))
                    makeContentRow(image: "waveform.path",
                                   content: AnyView(
                                    Toggle(isOn: $userSettings.hapticFeedback) {
                                        Text("Haptic feedback")
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                   ))
                }
                
                if userSettings.bookmarks.count > 0 {
                    Section(header: Text("Pinned charts"),
                            footer: Text("These charts will be shown below default charts for every server")) {
                        ForEach(userSettings.bookmarks, id: \.self) { chart in
                            Text(chart)
                        }
                        .onDelete(perform: deleteBookmarks)
                    }
                }
                
                if userSettings.ignoredAlarms.count > 0 {
                    Section(header: Text("Hidden alarms")) {
                        ForEach(userSettings.ignoredAlarms, id: \.self) { alarm in
                            Text(alarm)
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
            .listStyle(InsetGroupedListStyle())
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
