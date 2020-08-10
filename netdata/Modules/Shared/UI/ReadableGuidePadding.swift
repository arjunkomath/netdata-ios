//
//  ReadableGuidePadding.swift
//  netdata
//
//  Created by Arjun Komath on 10/8/20.
//

import SwiftUI

private struct ReadableGuidePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontal

    func body(content: Content) -> some View {
       content.padding(.horizontal, horizontal == .regular ? 84: 16)
    }
}

extension View {
    func readableGuidePadding() -> some View {
        modifier(ReadableGuidePadding())
    }
}
