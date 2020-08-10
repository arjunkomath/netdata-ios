//
//  WelcomeScreen.swift
//  netdata
//
//  Created by Arjun Komath on 4/8/20.
//

import SwiftUI

struct WelcomeScreen: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            TitleView()
            
            Spacer()
            
            VStack(alignment: .leading) {
                InformationDetailView(title: "Real-time monitoring on the go",
                                      subTitle: "Monitor everything in real time on your mobile device",
                                      imageName: "paperplane")
                
                InformationDetailView(title: "Seamless connection",
                                      subTitle: "Works out-of-the-box with any Netdata instance",
                                      imageName: "wifi")
                
                InformationDetailView(title: "Free & Open-source",
                                      subTitle: "Open-source iOS, iPadOS and macOS client",
                                      imageName: "globe")
            }
            .padding(.horizontal)
            
            Spacer(minLength: 30)
            
            Button(action: {
                FeedbackGenerator.shared.triggerNotification(type: .success)
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("Continue")
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                    .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(Color.accentColor))
                    .padding(.bottom)
            }
            .padding(.horizontal)
        }
    }
}

struct TitleView: View {
    var body: some View {
        VStack {
            Text("Welcome to")
                .largeTitleText()
            
            Text("Netdata")
                .largeTitleText()
                .foregroundColor(.accentColor)
        }
    }
}

struct InformationDetailView: View {
    var title: String = "title"
    var subTitle: String = "subTitle"
    var imageName: String = "car"
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundColor(.accentColor)
                .padding()
                .accessibility(hidden: true)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)
                
                Text(subTitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top)
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}
