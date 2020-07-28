//
//  ReadableGuidePadding.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

private struct ReadableGuidePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontal

    func body(content: Content) -> some View {
       content.padding(.horizontal, horizontal == .regular ? 84 : 0)
    }
}

extension View {
    func readableGuidePadding() -> some View {
        modifier(ReadableGuidePadding())
    }
}
