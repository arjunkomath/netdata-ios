//
//  AddServerForm.swift
//  netdata
//
//  Created by Arjun Komath on 11/7/20.
//

import SwiftUI
import Alamofire

struct AddServerForm: View {
    @EnvironmentObject private var service: ServerService
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var url = ""
    
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
                .foregroundColor(.red)
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            self.checkForMissingField()
            if self.validationError {
                return
            }
            
            self.validatingUrl = true
            
            NetDataApiService.validateServerInfo(baseUrl: self.url) { (valid) in
                if valid == false {
                    self.validatingUrl = false
                    return
                }
                
                self.validatingUrl = false
                let server = Server(name: self.name,
                                    description: self.description,
                                    url: self.url)
                
                ServerService.shared.add(server: server)
                
                self.presentationMode.wrappedValue.dismiss()
            }
            
        }) {
            Image(systemName: "checkmark").imageScale(.large)
        }
    }
}

struct AddServerForm_Previews: PreviewProvider {
    static var previews: some View {
        AddServerForm()
    }
}
