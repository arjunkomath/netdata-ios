//
//  SettingsView.swift
//  netdata
//
//  Created by Arjun Komath on 12/7/20.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var service: ServerService
    
    private var versionNumber: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? NSLocalizedString("Error", comment: "")
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? NSLocalizedString("Error", comment: "")
    }
    
    private func makeRow(image: String,
                         text: LocalizedStringKey,
                         link: URL? = nil,
                         color: Color? = .primary) -> some View {
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
                               detail: String) -> some View {
        HStack {
            Image(systemName: image)
                .imageScale(.medium)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
            Text(detail)
                .foregroundColor(.gray)
                .font(.callout)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Data")) {
                    makeRow(image: self.service.isCloudEnabled ? "icloud.fill" : "icloud.slash",
                            text: "iCloud sync \(self.service.isCloudEnabled ? "enabled" : "disabled")",
                            color: self.service.isCloudEnabled ? .green : .red)
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
            .readableGuidePadding()
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
