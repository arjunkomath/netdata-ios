//
//  AddServerForm.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import Combine

struct AddServerForm: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel = ServerListViewModel()
        
    var body: some View {
        NavigationView {
            Form {
                Section(header: makeSectionHeader(text: "Install Netdata Agent on Server"),
                        footer: Text("The Netdata Agent is 100% open source and powered by more than 300 contributors. All components are available under the GPL v3 license on GitHub.")) {
                    makeRow(image: "gear",
                            text: "View Installation guide",
                            link: URL(string: "https://learn.netdata.cloud/#installation"),
                            color: .accentColor)
                }
                
                Section(header: makeSectionHeader(text: "Enter Server details"),
                        footer: Text("HTTPS is required for connections over the internet\nHTTP is allowed for LAN connections with IP or mDNS domains")) {
                    if viewModel.validationError {
                        ErrorMessage(message: viewModel.validationErrorMessage)
                    }
                    
                    TextField("Name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description)
                    TextField("NetData Server Full URL", text: $viewModel.url)
                        .autocapitalization(UITextAutocapitalizationType.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: makeSectionHeader(text: "Authentication"),
                        footer: Text("Base64 encoded authorisation header will be stored in iCloud")) {
                    HStack {
                        Toggle(isOn: $viewModel.enableBasicAuth) {
                            Text("Basic Authentication")
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    
                    if viewModel.basicAuthvalidationError {
                        ErrorMessage(message: viewModel.basicAuthvalidationErrorMessage)
                    }
                    
                    if viewModel.enableBasicAuth {
                        TextField("Username", text: $viewModel.basicAuthUsername)
                            .autocapitalization(UITextAutocapitalizationType.none)
                        SecureField("Password", text: $viewModel.basicAuthPassword)
                    }
                }
            }
            .navigationBarTitle("Add Server", displayMode: .inline)
            .navigationBarItems(leading: dismissButton, trailing: saveButton)
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
    
    private var dismissButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.small)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .accentColor(Color.red)
    }
    
    private var saveButton: some View {
        Button(action: {
            if viewModel.validateForm() == false {
                FeedbackGenerator.shared.triggerNotification(type: .error)
                return
            }
            
            async {
                await viewModel.addServer()
                self.presentationMode.wrappedValue.dismiss()
            }
        }) {
            if (viewModel.validatingUrl) {
                ProgressView()
            } else {
                Text("Add")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .alert(isPresented: $viewModel.invalidUrlAlert) {
            Alert(title: Text("Oops!"), message: Text("You've entered an invalid URL"), dismissButton: .default(Text("OK")))
        }
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }
}

struct AddServerForm_Previews: PreviewProvider {
    static var previews: some View {
        AddServerForm()
    }
}
