//
//  SectionHeaderTextStyle.swift
//  netdata
//
//  Created by Arjun Komath on 4/8/20.
//

import SwiftUI

extension Text {
    func sectionHeaderStyle() -> Text {
        self
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundColor(.gray)
    }

    func largeTitleText() -> Text {
        self
            .fontWeight(.black)
            .font(.system(size: 36))
    }
}
