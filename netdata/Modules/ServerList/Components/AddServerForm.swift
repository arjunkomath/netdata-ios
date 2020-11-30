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
    
    @State private var invalidUrlAlert = false
    
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
            }
            .navigationBarTitle("Setup Server")
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
    
    private func checkForMissingField() {
        if (viewModel.name.isEmpty || viewModel.description.isEmpty || viewModel.url.isEmpty) {
            viewModel.validationError = true
            viewModel.validationErrorMessage = "Please fill all the fields"
            return
        }
        
        if (!viewModel.validateUrl(urlString: viewModel.url)) {
            self.invalidUrlAlert = true
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
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(BorderedBarButtonStyle())
        .alert(isPresented: $invalidUrlAlert) {
            Alert(title: Text("Oops!"), message: Text("You've entered an invalid URL"), dismissButton: .default(Text("OK")))
        }
    }
}

struct AddServerForm_Previews: PreviewProvider {
    static var previews: some View {
        AddServerForm()
    }
}
