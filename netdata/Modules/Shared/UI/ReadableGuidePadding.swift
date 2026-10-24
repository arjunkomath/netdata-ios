//
//  ReadableGuidePadding.swift
//  netdata
//
//  Created by Arjun Komath on 10/8/20.
//

import SwiftUI

private struct ReadableGuidePadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func readableGuidePadding() -> some View {
        modifier(ReadableGuidePadding())
    }
}
