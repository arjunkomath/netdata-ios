//
//  ErrorMessage.swift
//  netdata
//
//  Created by Arjun Komath on 26/7/20.
//

import SwiftUI

struct ErrorMessage: View {
    var message: String
    
    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .imageScale(.large)
                .frame(width: 24)
            Text(message)
                .font(.headline)
        }
        .foregroundColor(.red)
    }
}

struct ErrorMessage_Previews: PreviewProvider {
    static var previews: some View {
        ErrorMessage(message: "This is an Error")
    }
}
