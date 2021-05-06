//
//  BottomBar.swift
//  netdata
//
//  Created by Arjun Komath on 6/5/21.
//

import SwiftUI

struct BottomBar<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                content()
            }
            .frame(height: 48)
            .background(Color(UIColor.systemBackground))
        }
        .transition(.move(edge: .bottom))
    }
}

struct BottomBar_Previews: PreviewProvider {
    static var previews: some View {
        BottomBar {
            Text("Hello")
        }
    }
}
