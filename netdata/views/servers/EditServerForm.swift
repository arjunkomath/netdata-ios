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
    
    let editingServer: NDServer?
    
    @State private var name = ""
    @State private var description = ""
    @State private var url = ""
    
    @State private var validatingUrl = false
    @State private var validationError = false
    @State private var validationErrorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Server details"),
                        footer: Text("HTTPS is required to connect")) {
                    if validationError {
                        ErrorMessage(message: self.validationErrorMessage)
                    }
                    
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("NetData Server URL", text: $url)
                }
            }
            .navigationBarTitle("Edit Server")
            .navigationBarItems(leading: dismissButton, trailing: saveButton)
            .onAppear {
                if let server = self.editingServer {
                    self.name = server.name
                    self.description = server.description
                    self.url = server.url
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func checkForMissingField() {
        if (name.isEmpty || description.isEmpty || url.isEmpty) {
            validationError = true
            validationErrorMessage = "Please fill all the fields"
            return
        }
        
        validationError = false
        validationErrorMessage = ""
    }
    
    private var dismissButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.medium)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .foregroundColor(.red)
        .accentColor(Color.red.opacity(0.2))
    }
    
    private var saveButton: some View {
        Button(action: {
            self.checkForMissingField()
            if self.validationError {
                return
            }
            
            self.validatingUrl = true
            
            var cancellable = Set<AnyCancellable>()
            
            NetDataAPI
                .getInfo(baseUrl: self.url)
                .subscribe(on: DispatchQueue.global())
                .sink(receiveCompletion: { completion in
                    print(completion)
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.validatingUrl = false
                            self.validationError = true
                            self.validationErrorMessage = "Invalid server URL"
                        }
                        
                        debugPrint(error)
                    }
                },
                receiveValue: { info in
                    var updateFavourite = false
                    if userSettings.favouriteServerId == self.editingServer?.id {
                        updateFavourite = true
                    }
                    
                    var server = NDServer(name: self.name,
                                          description: self.description,
                                          url: self.url,
                                          serverInfo: info)
                    
                    if let record = self.editingServer?.record {
                        server.record = record

                        ServerService.shared.edit(server: server)
                        
                        if updateFavourite {
                            userSettings.favouriteServerId = server.id
                            userSettings.favouriteServerUrl = server.url
                        }
                        
                        ServerService.shared.refresh()
                    }
                    
                    self.presentationMode.wrappedValue.dismiss()
                })
                .store(in: &cancellable)
        }) {
            if (self.validatingUrl) {
                ProgressView()
            } else {
                Text("Save")
                    .foregroundColor(.green)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .foregroundColor(.green)
        .accentColor(Color.green.opacity(0.2))
    }
}

struct EditServerForm_Previews: PreviewProvider {
    static var previews: some View {
        EditServerForm(editingServer: nil)
    }
}
