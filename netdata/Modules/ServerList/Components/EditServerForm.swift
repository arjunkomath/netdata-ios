//
//  EditServerForm.swift
//  netdata
//
//  Created by Arjun Komath on 26/7/20.
//

import SwiftUI
import AlertToast
import Combine

struct EditServerForm: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var userSettings = UserSettings()
    @StateObject var viewModel = ServerListViewModel()
    
    let editingServer: NDServer?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: makeSectionHeader(text: "Server details"),
                        footer: Text("HTTPS is required for connections over the internet\nHTTP is allowed for LAN connections with IP or mDNS domains")) {
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
                    await self.updateServer()
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
            .navigationBarTitle("Edit Server", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    dismissButton
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    saveButton
                    Spacer()
                }
            }
            .task {
                if let server = self.editingServer {
                    viewModel.name = server.name
                    viewModel.description = server.description
                    viewModel.url = server.url
                    viewModel.isFavourite = server.isFavourite
                }
            }
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
                await updateServer()
            }
        }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Save")
                    .fontWeight(.bold)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .disabled(viewModel.validatingUrl)
    }
    
    func updateServer() async {
        if await viewModel.validateForm() == false {
            FeedbackGenerator.shared.triggerNotification(type: .error)
            return
        }
        
        Task {
            if let editingServer = editingServer {
                if await viewModel.updateServer(editingServer: editingServer) == true {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    func makeSectionHeader(text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }
}

struct EditServerForm_Previews: PreviewProvider {
    static var previews: some View {
        EditServerForm(editingServer: nil)
    }
}
