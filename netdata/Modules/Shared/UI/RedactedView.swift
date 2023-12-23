//
//  RedactedView.swift
//  netdata
//
//  Created by Arjun on 23/12/2023.
//

import SwiftUI

struct RedactedView<Content: View>: View {
    let loading: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if loading {
            content().redacted(reason: .placeholder)
        } else {
            content()
        }
    }
}

#Preview {
    RedactedView(loading: true) {
        Text("hello")
    }
}
