//
//  netdataApp.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

@main
struct netdataApp: App {
    var body: some Scene {
        WindowGroup {
            TabberView()
                .environmentObject(ServerService.shared)
        }
    }
}
