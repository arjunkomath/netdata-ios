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
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    content()
                }
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    ServerDetailItem(label: "Test") {
        Text("Hello")
    }
}
