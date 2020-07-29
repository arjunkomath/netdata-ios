//
//  BorderedRoundedButton.swift
//  netdata
//
//  Created by Thomas Ricouard on 04/05/2020.
//

import Foundation
import SwiftUI

public struct BorderedBarButtonStyle: ButtonStyle {
    public init() { }
    
    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        #if targetEnvironment(macCatalyst)
        configuration
            .label
            .padding(6)
            .foregroundColor(.accentColor)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).foregroundColor(Color.accentColor.opacity(0.2)))
        #else
        configuration
            .label
            .padding(10)
            .foregroundColor(.accentColor)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).foregroundColor(Color.accentColor.opacity(0.2)))
        #endif
    }
}
