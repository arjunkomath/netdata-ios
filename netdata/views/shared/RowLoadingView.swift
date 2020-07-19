//
//  RowLoadingView.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI

struct RowLoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

struct RowLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        RowLoadingView()
    }
}
