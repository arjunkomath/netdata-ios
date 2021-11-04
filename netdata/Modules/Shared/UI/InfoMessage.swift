//
//  InfoMessage.swift
//  netdata
//
//  Created by Arjun on 4/11/21.
//

import SwiftUI

struct InfoMessage: View {
    var message: String
    
    var body: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(message)
                .font(.headline)
        }
    }
}

struct InfoMessage_Previews: PreviewProvider {
    static var previews: some View {
        InfoMessage(message: "This is an info")
    }
}
