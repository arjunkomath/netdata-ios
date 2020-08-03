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
                Section(header: Text("Update Server details"),
                        footer: Text("HTTPS is required to connect")) {
                    if viewModel.validationError {
                        ErrorMessage(message: viewModel.validationErrorMessage)
                    }
                    
                    TextField("Name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description)
                    TextField("NetData Server URL", text: $viewModel.url)
                }
            }
            .navigationBarTitle("Edit Server")
            .navigationBarItems(leading: dismissButton, trailing: saveButton)
            .onAppear {
                if let server = self.editingServer {
                    viewModel.name = server.name
                    viewModel.description = server.description
                    viewModel.url = server.url
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func checkForMissingField() {
        if (viewModel.name.isEmpty || viewModel.description.isEmpty || viewModel.url.isEmpty) {
            viewModel.validationError = true
            viewModel.validationErrorMessage = "Please fill all the fields"
            return
        }
        
        viewModel.validationError = false
        viewModel.validationErrorMessage = ""
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
            self.checkForMissingField()
            if viewModel.validationError {
                FeedbackGenerator.shared.triggerNotification(type: .error)
                return
            }

            viewModel.updateServer(editingServer: editingServer!) { server in
                self.presentationMode.wrappedValue.dismiss()
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
    }
}

struct EditServerForm_Previews: PreviewProvider {
    static var previews: some View {
        EditServerForm(editingServer: nil)
    }
}
