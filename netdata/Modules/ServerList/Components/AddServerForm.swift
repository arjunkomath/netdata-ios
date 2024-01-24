//
//  AddServerForm.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import Combine
import AlertToast

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
                
                Section(header: makeSectionHeader(text: "Server details"),
                        footer: Text("HTTPS is recommended for connections over the internet\nHTTP is allowed for LAN connections with IP or mDNS domains")) {
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
                    
                    if viewModel.enableBasicAuth {
                        TextField("Username", text: $viewModel.basicAuthUsername)
                            .autocapitalization(UITextAutocapitalizationType.none)
                        SecureField("Password", text: $viewModel.basicAuthPassword)
                    }
                }
            }
            .onSubmit {
                Task {
                    await self.addServer()
                }
            }
            .toast(isPresenting: $viewModel.validationError, duration: 5) {
                AlertToast(
                    displayMode: .banner(.pop),
                    type: .error(.red),
                    title: viewModel.validationErrorMessage
                )
            }
            .toast(isPresenting: $viewModel.basicAuthvalidationError, duration: 5) {
                AlertToast(
                    displayMode: .banner(.pop),
                    type: .error(.red),
                    title: viewModel.basicAuthvalidationErrorMessage
                )
            }
            .submitLabel(.done)
            .navigationBarTitle("Add Server", displayMode: .inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    saveButton
                    Spacer()
                }
                ToolbarItem(placement: .navigation) {
                    dismissButton
                }
            }
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
            Task {
                await addServer()
            }
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add")
                    .fontWeight(.bold)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .disabled(viewModel.validatingUrl)
    }
    
    func addServer() async {
        if await viewModel.validateForm() == false {
            FeedbackGenerator.shared.triggerNotification(type: .error)
            return
        }
        
        if await viewModel.addServer() == true {
            self.presentationMode.wrappedValue.dismiss()
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
