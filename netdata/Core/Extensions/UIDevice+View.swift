//
//  UIDevice.swift
//  netdata
//
//  Created by Arjun on 6/11/21.
//

import Foundation
import SwiftUI

extension UIDevice {
      // Checks if we run in Mac Catalyst Optimized For Mac Idiom
      var isCatalystMacIdiom: Bool {
            if #available(iOS 14, *) {
                  return UIDevice.current.userInterfaceIdiom == .mac
            } else {
                  return false
            }
      }
}

extension View {
    /// Applies the given transform if we not running in Mac Catalyst Optimized For Mac Idiom
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `ifNotMacCatalyst`<Content: View>(transform: (Self) -> Content) -> some View {
        if !UIDevice.current.isCatalystMacIdiom {
            transform(self)
        } else {
            self
        }
    }
}
