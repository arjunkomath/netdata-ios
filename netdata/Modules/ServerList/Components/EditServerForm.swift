//
//  EditServerForm.swift
//  netdata
//
//  Created by Arjun Komath on 26/7/20.
//

import SwiftUI
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
            .onSubmit {
                Task {
                    await self.updateServer()
                }
            }
            .submitLabel(.done)
            .navigationBarTitle("Edit Server", displayMode: .inline)
            .navigationBarItems(leading: dismissButton, trailing: saveButton)
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
            if (viewModel.validatingUrl) {
                ProgressView()
            } else {
                Text("Save")
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
    
    func updateServer() async {
        if viewModel.validateForm() == false {
            FeedbackGenerator.shared.triggerNotification(type: .error)
            return
        }
        
        Task {
            if let editingServer = editingServer {
                await viewModel.updateServer(editingServer: editingServer)
                self.presentationMode.wrappedValue.dismiss()
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
