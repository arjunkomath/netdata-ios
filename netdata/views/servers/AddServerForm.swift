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
    
    @State private var name = "test"
    @State private var description = "test"
    @State private var url = "https://netdata.code.techulus.com"
    
    @State private var validatingUrl = false
    @State private var validationError = false
    
    var body: some View {
        NavigationView {
            Form {
                Group {
                    if validationError {
                        Text("Please fill all the fields")
                            .foregroundColor(.red)
                    }
                    
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("NetData Server URL", text: $url)
                }
                
                Group {
                    if validatingUrl {
                        HStack {
                            RowLoadingView()
                        }
                    }
                }
            }
            .navigationBarTitle("Add Server")
            .navigationBarItems(leading: dismissButton, trailing: saveButton)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func checkForMissingField() {
        if (name.isEmpty || description.isEmpty || url.isEmpty) {
            validationError = true
            return
        }
        
        validationError = false
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
                        self.validatingUrl = false
                        debugPrint(error)
                    }
                },
                receiveValue: { info in
                    self.validatingUrl = false
                    let server = NDServer(name: self.name,
                                          description: self.description,
                                          url: self.url,
                                          serverInfo: info)
                    
                    ServerService.shared.add(server: server)
                    
                    self.presentationMode.wrappedValue.dismiss()
                })
                .store(in: &cancellable)
        }) {
            Image(systemName: "checkmark")
                .imageScale(.medium)
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
