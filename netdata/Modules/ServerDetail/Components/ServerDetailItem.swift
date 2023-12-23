//
//  ServerDetailItem.swift
//  netdata
//
//  Created by Arjun on 23/12/2023.
//

import SwiftUI

struct ServerDetailItem<Content: View>: View {
    var label: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            HStack {
                content()
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    ServerDetailItem(label: "Test") {
        Text("Hello")
    }
}
