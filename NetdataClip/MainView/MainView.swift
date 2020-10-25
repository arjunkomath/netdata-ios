//
//  ContentView.swift
//  NetdataClip
//
//  Created by Arjun Komath on 25/10/20.
//

import SwiftUI
import Combine

struct MainView: View {
    @State private var serverUrl = ""
    
    @State private var validationError = false
    @State private var validationErrorMessage = ""
    @State private var invalidUrlAlert = false
    
    @State private var showServerDetail = false
    
    @State private var validating = false
    
    @StateObject var viewModel = ServerDetailViewModel()
        
    var body: some View {
        VStack {
            Text("Netdata")
                .padding(.top)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
            
            Form {
                Section(header: Text("Install Netdata Agent on Server"),
                        footer: Text("The Netdata Agent is 100% open source and powered by more than 300 contributors. All components are available under the GPL v3 license on GitHub.")) {
                    makeRow(image: "gear",
                            text: "View Installation guide",
                            link: URL(string: "https://learn.netdata.cloud/#installation"),
                            color: .accentColor)
                }
                
                Section(header: Text("Enter Server URL"),
                        footer: Text("HTTPS is required to connect")) {
                    
                    if validationError {
                        ErrorMessage(message: validationErrorMessage)
                    }
                    
                    TextField("NetData Server URL", text: $serverUrl)
                        .autocapitalization(UITextAutocapitalizationType.none)
                        .disableAutocorrection(true)
                }
                .alert(isPresented: $invalidUrlAlert) {
                    Alert(title: Text("Oops!"), message: Text("You've entered an invalid URL"), dismissButton: .default(Text("OK")))
                }
            }
            .sheet(isPresented: $showServerDetail, content: {
                ServerDetailDemoView(serverUrl: self.serverUrl)
            })
            
            Button(action: {
                self.validationError = false
                
                if (self.serverUrl.isEmpty) {
                    self.validationError = true
                    self.validationErrorMessage = "Please enter the URL for Netdata server"
                    return
                }
                
                if (!self.isValidUrl(urlString: self.serverUrl)) {
                    self.invalidUrlAlert = true
                    return
                }
                
                self.validating = true
                self.viewModel.validateServer(serverUrl: serverUrl) { isValid in
                    self.validating = false
                    
                    if !isValid {
                        self.validationError = true
                        self.validationErrorMessage = "Invalid server URL! Please ensure Netdata has been installed on the server."
                        return
                    }
                    
                    self.showServerDetail = isValid
                }
            }) {
                if self.validating {
                        ProgressView()
                            .padding()
                } else {
                    Text("Start monitoring")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(Color.accentColor))
                        .padding(.bottom)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func makeRow(image: String,
                         text: LocalizedStringKey,
                         link: URL? = nil,
                         color: Color? = .primary) -> some View {
        HStack {
            Image(systemName: image)
                .imageScale(.small)
                .foregroundColor(color)
                .frame(width: 24)
            Group {
                if let link = link {
                    Link(text, destination: link)
                } else {
                    Text(text)
                }
            }
            .font(.body)
            
            Spacer()
        }
    }
    
    private func isValidUrl(urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
