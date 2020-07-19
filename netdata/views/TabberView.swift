//
//  ContentView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

struct TabberView: View {
    
    var body: some View {
        TabView() {
            ServerListView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Servers")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}
