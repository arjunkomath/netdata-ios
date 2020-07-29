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
                Section(header: Text("Install Netdata Agent on Server"),
                        footer: Text("The Netdata Agent is 100% open source and powered by more than 300 contributors. All components are available under the GPL v3 license on GitHub.")) {
                    makeRow(image: "gear",
                            text: "View Installation guide",
                            link: URL(string: "https://learn.netdata.cloud/#installation"),
                            color: .accentColor)
                }
                
                Section(header: Text("Enter Server details"),
                        footer: Text("HTTPS is required to connect")) {
                    if viewModel.validationError {
                        ErrorMessage(message: viewModel.validationErrorMessage)
                    }
                    
                    TextField("Name", text: $viewModel.name)
                    TextField("Description", text: $viewModel.description)
                    TextField("NetData Server URL", text: $viewModel.url)
                }
            }
            .navigationBarTitle("Setup Server")
            .navigationBarItems(leading: dismissButton, trailing: saveButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func makeRow(image: String,
                         text: LocalizedStringKey,
                         link: URL? = nil,
                         color: Color? = .primary) -> some View {
        HStack {
            Image(systemName: image)
                .imageScale(.medium)
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
                .imageScale(.medium)
        }
        .buttonStyle(BorderedBarButtonStyle())
        .foregroundColor(.red)
        .accentColor(Color.red.opacity(0.2))
    }
    
    private var saveButton: some View {
        Button(action: {
            self.checkForMissingField()
            if viewModel.validationError {
                FeedbackGenerator.shared.triggerNotification(type: .error)
                return
            }
            
            viewModel.addServer { _ in
                self.presentationMode.wrappedValue.dismiss()
            }
        }) {
            if (viewModel.validatingUrl) {
                ProgressView()
            } else {
                Text("Add")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.green)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .foregroundColor(.green)
        .accentColor(Color.green.opacity(0.2))
    }
}

struct AddServerForm_Previews: PreviewProvider {
    static var previews: some View {
        AddServerForm()
    }
}
