//
//  AddServerForm.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import Combine

struct AddServerForm: View {
    @EnvironmentObject private var service: ServerService
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var url = ""
    
    @State private var validatingUrl = false
    @State private var validationError = false
    @State private var validationErrorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Install Netdata Agent on Server"),
                        footer: Text("The Netdata Agent is 100% open source and powered by more than 300 contributors. All components are available under the GPL v3 license on GitHub.")) {
                    makeRow(image: "gear",
                            text: "View Installation guide",
                            link: URL(string: "https://learn.netdata.cloud/#installation"),
                            color: .blue)
                }
                
                Section(header: Text("Enter Server details"),
                        footer: Text("HTTPS is required to connect")) {
                    if validationError {
                        ErrorMessage(message: self.validationErrorMessage)
                    }
                    
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("NetData Server URL", text: $url)
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
                    let server = NDServer(name: self.name,
                                          description: self.description,
                                          url: self.url,
                                          serverInfo: info)
                    
                    ServerService.shared.add(server: server)
                    
                    self.presentationMode.wrappedValue.dismiss()
                })
                .store(in: &cancellable)
        }) {
            if (self.validatingUrl) {
                ProgressView()
            } else {
                Text("Add")
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
