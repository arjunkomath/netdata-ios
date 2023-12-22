//
//  SupportOptions.swift
//  netdata
//
//  Created by Arjun on 22/12/2023.
//

import SwiftUI

struct SupportOptions: View {
    var body: some View {
        Menu(content: {
            makeLinkButton(label: "Report an issue", link: "https://github.com/arjunkomath/netdata-ios/issues")
            makeLinkButton(label: "Q&A", link: "https://github.com/arjunkomath/netdata-ios/discussions/categories/q-a")
        }, label: {
            Label("Support", systemImage: "lifepreserver")
        })
    }
    
    @ViewBuilder
    private func makeLinkButton(label: String,
                                link: String) -> some View {
        Button {
            guard let url = URL(string: link) else { return }
            UIApplication.shared.open(url)
        } label: {
            Text(label)
        }
    }
}

#Preview {
    SupportOptions()
}
