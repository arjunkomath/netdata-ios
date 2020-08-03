//
//  SectionHeaderTextStyle.swift
//  netdata
//
//  Created by Arjun Komath on 4/8/20.
//

import SwiftUI

struct SectionHeaderTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.callout)
            .foregroundColor(.gray)
    }
}
